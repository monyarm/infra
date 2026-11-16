"""ESC/POS printing over Bluetooth RFCOMM, and a CUPS backend.

Speaks classic Bluetooth SPP (unprivileged, no pairing) to DP-L1S family
thermal printers, or to any ESC/POS printer that takes GS v 0 raster bands.

A link-holder service (`tp --serve`) can keep the RFCOMM link open between
jobs, because the firmware refuses a connection that arrives while it is still
busy with the previous one. Clients use it through a unix socket and fall back
to a direct connection when it is not running.
"""

import argparse
import contextlib
import io
import os
import re
import socket
import subprocess
import sys
import time
import unicodedata

FONT_PATH = os.environ.get("TP_FONT", "@FONT@")
PDFTOTEXT = os.environ.get("TP_PDFTOTEXT", "@PDFTOTEXT@")
FCMATCH = os.environ.get("TP_FCMATCH", "@FCMATCH@")

# Link-holder service socket. Absent socket = talk to the printer directly.
SOCKET_ENV = "TP_SOCKET"
DEFAULT_SOCKET = "/run/thermal-printer/tp.sock"
# Drop the Bluetooth link after this long without a job, so the printer sleeps.
IDLE_TIMEOUT = int(os.environ.get("TP_IDLE", "60"))

# 384 dots = 56 mm paper at 203 dpi.
WIDTH = 384
COLUMNS = 32
FONT_SIZE = 20
CELL = WIDTH // COLUMNS
# Hard threshold, no dithering: dithering eats thin text strokes.
THRESHOLD = 160
# One big raster is silently dropped by the firmware; feed it bands instead.
BAND_LINES = 24
BAND_DELAY = 0.2
# 80 dots clears the head and tears off cleanly; 60 is too tight.
FEED_DOTS = 80


def feed(dots):
    """ESC J n: feed n dots."""
    return b"\x1b\x4a" + bytes([dots])


# Vendor battery query. The printer only answers it when the command is
# preceded by the enable command plus twelve 0x00 wake bytes.
WAKE = bytes.fromhex("10FFF103") + bytes(12)
BATTERY_QUERY = bytes.fromhex("10FF50F1")
# Below this the printer refuses to print. The red flashing LED is the only
# other indicator: the 10 FF 40 status byte does not report it.
BATTERY_MIN = 22


class LowBattery(Exception):
    pass


MAC_RE = re.compile(r"^(?:[0-9A-Fa-f]{2}:){5}[0-9A-Fa-f]{2}$")
PNG_MAGIC = b"\x89PNG\r\n\x1a\n"
JPEG_MAGIC = b"\xff\xd8\xff"
PDF_MAGIC = b"%PDF"
ESC_MAGIC = (b"\x1b", b"\x1d")

# Firmware prints any non-ASCII byte as a solid black block.
LATIN_MAP = {
    "°": "deg",
    "€": "EUR",
    "£": "GBP",
    "–": "-",
    "—": "-",
    "−": "-",
    "´": "'",
    "‘": "'",
    "’": "'",
    "“": '"',
    "”": '"',
    "…": "...",
    "ø": "o",
    "Ø": "O",
    "ß": "ss",
    "æ": "ae",
    "Æ": "AE",
    "œ": "oe",
    "Œ": "OE",
    "ł": "l",
    "Ł": "L",
    "đ": "d",
    "Đ": "D",
    "þ": "th",
    "Þ": "Th",
    "ð": "d",
    "Ð": "D",
}

# Vendor queries documented for the DP-L1S (LuckPrinter SDK). Untested over
# SPP -- the reference work was done over BLE -- so print raw bytes when a
# reply does not match the documented shape.
INFO_QUERIES = [
    ("model", "10FF20F0"),
    ("firmware", "10FF20F1"),
    ("serial", "10FF20F2"),
    ("battery", "10FF50F1"),
    ("status", "10FF40"),
    ("density", "10FF11"),
    ("speed", "10FF20A0"),
    ("shutdown", "10FF13"),
    ("all", "10FF70"),
]

STATUS_BITS = [
    (0, "printing"),
    (1, "cover open"),
    (2, "paper empty"),
    (3, "low battery"),
    (5, "charging"),
    (4, "overheating"),
    (6, "overheating"),
]


def ascii_fold(text):
    for src, dst in LATIN_MAP.items():
        text = text.replace(src, dst)
    text = unicodedata.normalize("NFKD", text)
    return "".join(c for c in text if ord(c) < 128)


def wrap(text, columns=COLUMNS):
    lines = []
    for raw in text.replace("\r\n", "\n").replace("\r", "\n").split("\n"):
        raw = raw.expandtabs(4).rstrip()
        if not raw:
            lines.append("")
            continue
        line = ""
        for word in raw.split(" "):
            while len(word) > columns:
                if line:
                    lines.append(line)
                    line = ""
                lines.append(word[:columns])
                word = word[columns:]
            if not line:
                line = word
            elif len(line) + 1 + len(word) <= columns:
                line = f"{line} {word}"
            else:
                lines.append(line)
                line = word
        lines.append(line)
    while lines and not lines[-1]:
        lines.pop()
    return lines or [""]


def load_font(name=None, size=FONT_SIZE):
    from PIL import ImageFont

    path = name or FONT_PATH
    if name and "/" not in name and not os.path.exists(name):
        # A font name, not a file: ask fontconfig which file that is.
        res = subprocess.run(
            [FCMATCH, "-f", "%{file}", name],
            check=False,
            stdout=subprocess.PIPE,
            stderr=subprocess.DEVNULL,
        )
        path = res.stdout.decode().strip()
        if not path:
            raise OSError(f"font not found: {name}")
    return ImageFont.truetype(path, size)


def text_image(text, center=False, font_name=None, size=FONT_SIZE, trim=True):
    from PIL import Image, ImageDraw

    font = load_font(font_name, size)
    fixed = font.getlength("i") == font.getlength("W")
    # Monospace: a whole-number cell keeps the columns inside 384 px. The
    # default font's own advance is 12.05 px at size 20.
    cell = round(font.getlength("W")) if fixed else 0
    columns = WIDTH // cell if fixed else COLUMNS
    lines = wrap(ascii_fold(text), columns)
    if trim:
        while lines and not lines[0]:
            lines.pop(0)
        while lines and not lines[-1]:
            lines.pop()
        lines = lines or [""]
    if not fixed:
        # Proportional font: shrink until the longest line fits the band.
        widest = max(font.getlength(line) for line in lines)
        if widest > WIDTH:
            font = load_font(font_name, max(8, round(size * WIDTH / widest)))
    ascent, descent = font.getmetrics()
    line_h = ascent + descent
    img = Image.new("L", (WIDTH, line_h * len(lines)), 255)
    draw = ImageDraw.Draw(img)
    for i, line in enumerate(lines):
        if fixed:
            left = (WIDTH - len(line) * cell) // 2 if center else 0
            for col, char in enumerate(line):
                draw.text((left + col * cell, i * line_h), char, font=font, fill=0)
        else:
            left = (WIDTH - round(font.getlength(line))) // 2 if center else 0
            draw.text((max(0, left), i * line_h), line, font=font, fill=0)
    return img


def image_raster(img):
    from PIL import Image

    img = img.convert("L")
    height = max(1, round(img.height * WIDTH / img.width))
    resample = getattr(Image, "Resampling", Image).LANCZOS
    return img.resize((WIDTH, height), resample)


def bands(img):
    gray = img.convert("L")
    # Black -> 255 so the packed bit is set; convert("1") alone would dither.
    bw = gray.point(lambda p: 255 if p < THRESHOLD else 0).convert("1")
    stride = (bw.width + 7) // 8
    data = bw.tobytes()
    for top in range(0, bw.height, BAND_LINES):
        height = min(BAND_LINES, bw.height - top)
        header = (
            b"\x1d\x76\x30\x00"
            + bytes([stride & 0xFF, stride >> 8])
            + height.to_bytes(2, "little")
        )
        yield header + data[top * stride : (top + height) * stride]


def connect(mac, channel, attempts=6):
    for attempt in range(attempts):
        sock = socket.socket(
            socket.AF_BLUETOOTH, socket.SOCK_STREAM, socket.BTPROTO_RFCOMM
        )
        try:
            sock.connect((mac, channel))
            return sock
        except OSError:
            sock.close()
            if attempt == attempts - 1:
                raise
            # The stack needs seconds between RFCOMM links; a job that starts
            # right after the previous one is refused until teardown settles.
            time.sleep(1.5)


def pdf_text(data):
    res = subprocess.run(
        [PDFTOTEXT, "-layout", "-", "-"],
        input=data,
        stdout=subprocess.PIPE,
        stderr=subprocess.DEVNULL,
        check=True,
    )
    return res.stdout.decode("utf-8", "replace").replace("\f", "\n")


def open_image(data):
    from PIL import Image

    img = Image.open(io.BytesIO(data))
    img.load()
    return img


def is_escpos(data):
    if not data.startswith(ESC_MAGIC):
        return False
    return b"\x1d\x76" in data


def read_reply(sock, timeout=0.6):
    sock.settimeout(timeout)
    out = b""
    try:
        while True:
            chunk = sock.recv(256)
            if not chunk:
                break
            out += chunk
    except TimeoutError:
        pass
    return out


def query(sock, command, timeout=0.6):
    sock.sendall(command)
    return read_reply(sock, timeout)


def battery(sock):
    """Battery percent, or None when the printer does not answer."""
    sock.sendall(WAKE)
    read_reply(sock, 0.3)  # wake reply, not a battery reading
    reply = query(sock, BATTERY_QUERY)
    if len(reply) >= 2:
        # Documented reply is 00 <percent>.
        return reply[1]
    return reply[0] if reply else None


def socket_path():
    return os.environ.get(SOCKET_ENV, DEFAULT_SOCKET)


def recv_exact(conn, size):
    buf = b""
    while len(buf) < size:
        chunk = conn.recv(size - len(buf))
        if not chunk:
            raise ConnectionError("connection closed")
        buf += chunk
    return buf


def rpc(op, payload=b"", path=None):
    """One request to the link-holder service; None when it is not running."""
    path = path or socket_path()
    if not os.path.exists(path):
        return None
    with socket.socket(socket.AF_UNIX, socket.SOCK_STREAM) as conn:
        conn.connect(path)
        conn.sendall(op + len(payload).to_bytes(4, "big") + payload)
        status = recv_exact(conn, 1)
        size = int.from_bytes(recv_exact(conn, 4), "big")
        reply = recv_exact(conn, size) if size else b""
    if status != b"O":
        raise OSError(reply.decode("utf-8", "replace") or "printer error")
    return reply


def check_battery(level):
    if level is not None and level < BATTERY_MIN:
        raise LowBattery(
            f"battery {level}%, below the {BATTERY_MIN}% print cutoff — charge the printer"
        )


class Session:
    """Printer access over the service socket, or the link directly."""

    def __init__(self, mac, channel):
        self.service = os.path.exists(socket_path())
        self.sock = None if self.service else connect(mac, channel)

    def query(self, command):
        if self.service:
            return rpc(b"Q", command) or b""
        return query(self.sock, command)

    def battery(self):
        if self.service:
            reply = rpc(b"B")
            return reply[0] if reply else None
        return battery(self.sock)

    def send(self, data):
        if self.service:
            rpc(b"J", data)
            return
        self.sock.sendall(data)

    def close(self):
        if self.sock is not None:
            self.sock.close()


def run_job(parts, mac, channel, feed_dots=FEED_DOTS):
    """Send each chunk with a pause, then feed and let the printer drain."""
    session = Session(mac, channel)
    try:
        check_battery(session.battery())
        for part in parts:
            session.send(part)
            time.sleep(BAND_DELAY)
        if feed_dots:
            session.send(feed(feed_dots))
        time.sleep(0.3)
    finally:
        session.close()


class Link:
    """Persistent RFCOMM link, opened on demand and dropped when idle."""

    def __init__(self, mac, channel):
        self.mac = mac
        self.channel = channel
        self.sock = None

    def get(self):
        if self.sock is None:
            self.sock = connect(self.mac, self.channel)
        return self.sock

    def drop(self):
        if self.sock is not None:
            try:
                self.sock.close()
            finally:
                self.sock = None


def serve_client(conn, link):
    while True:
        op = conn.recv(1)
        if not op:
            return
        size = int.from_bytes(recv_exact(conn, 4), "big")
        payload = recv_exact(conn, size) if size else b""
        try:
            if op == b"J":
                link.get().sendall(payload)
                reply = b""
            elif op == b"Q":
                reply = query(link.get(), payload)
            elif op == b"B":
                level = battery(link.get())
                reply = b"" if level is None else bytes([level])
            else:
                raise OSError(f"unknown request {op!r}")
            status = b"O"
        except OSError as exc:
            link.drop()
            status, reply = b"E", str(exc).encode()
        conn.sendall(status + len(reply).to_bytes(4, "big") + reply)


def serve(mac, channel, idle=IDLE_TIMEOUT):
    """Hold one RFCOMM link open and print whatever clients send.

    Keeping the link up avoids the reconnect churn that makes the firmware
    refuse back-to-back jobs.
    """
    path = socket_path()
    if os.path.exists(path):
        os.unlink(path)
    server = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
    server.bind(path)
    # CUPS runs the backend as lp, so every user needs the socket.
    os.chmod(path, 0o666)
    server.listen(8)
    server.settimeout(1.0)
    link = Link(mac, channel)
    last_used = time.monotonic()
    while True:
        try:
            conn, _ = server.accept()
        except TimeoutError:
            if link.sock is not None and time.monotonic() - last_used > idle:
                link.drop()
            continue
        with conn:
            try:
                serve_client(conn, link)
            except (ConnectionError, OSError):
                link.drop()
            last_used = time.monotonic()


def print_text(
    text,
    mac,
    channel,
    center=False,
    font_name=None,
    size=FONT_SIZE,
    trim=True,
    feed_dots=FEED_DOTS,
):
    image = text_image(text, center, font_name, size, trim)
    run_job(bands(image), mac, channel, feed_dots)


def print_image(img, mac, channel, feed_dots=FEED_DOTS):
    run_job(bands(image_raster(img)), mac, channel, feed_dots)


def print_job(
    data,
    mac,
    channel,
    center=False,
    font_name=None,
    size=FONT_SIZE,
    trim=True,
    feed_dots=FEED_DOTS,
):
    """Route one CUPS job body."""
    if is_escpos(data):
        run_job([data], mac, channel, feed_dots)
        return
    if data.startswith(PDF_MAGIC):
        body = pdf_text(data)
    elif data.startswith((PNG_MAGIC, JPEG_MAGIC)):
        print_image(open_image(data), mac, channel, feed_dots)
        return
    else:
        body = data.decode("utf-8", "replace")
    print_text(body, mac, channel, center, font_name, size, trim, feed_dots)


def describe(name, reply):
    if not reply:
        return "(no reply)"
    if name == "status":
        flags = [label for bit, label in STATUS_BITS if reply[0] >> bit & 1]
        return ", ".join(flags) if flags else "ready"
    if name == "shutdown" and len(reply) <= 2:
        return f"{int.from_bytes(reply, 'little')} min"
    text = reply.decode("ascii", "replace").replace("\x00", "").strip()
    if text and text.isprintable():
        return text
    return f"raw {reply.hex()}"


def print_info(mac, channel):
    session = Session(mac, channel)
    try:
        for name, command in INFO_QUERIES:
            if name == "battery":
                level = session.battery()
                print(f"battery: {'(no reply)' if level is None else f'{level}%'}")
                continue
            reply = session.query(bytes.fromhex(command))
            print(f"{name}: {describe(name, reply)}")
    finally:
        session.close()
    return 0


def target(uri, mac, channel):
    if uri.startswith("thermal://"):
        # A colon-bearing host is an invalid device-uri for CUPS, so the queue
        # URI carries the MAC with dashes; fold them back here.
        netloc = uri[len("thermal://") :].split("/")[0].replace("-", ":")
        if MAC_RE.match(netloc):
            mac = netloc
        else:
            host, _, port = netloc.rpartition(":")
            if MAC_RE.match(host):
                mac = host
            if port.isdigit():
                channel = int(port)
    return mac, channel


def cups(argv, mac, channel):
    rest = [a for a in argv[1:] if a != "--cups"]
    mac, channel = target(rest[0] if rest else "", mac, channel)
    data = sys.stdin.buffer.read()
    if not data and rest:
        # cupsd runs a raw single-file job with no filter, so the document
        # bytes are not on stdin (that is /dev/null); argv[6], the last arg,
        # is the spool file path instead.
        with contextlib.suppress(OSError), open(rest[-1], "rb") as spool:
            data = spool.read()
    try:
        print_job(data, mac, channel)
    except (LowBattery, OSError, subprocess.CalledProcessError) as err:
        print(f"thermal: {err}", file=sys.stderr)
        return 1
    return 0


def cli(argv, mac, channel):
    parser = argparse.ArgumentParser(
        prog="tp",
        description="Print text, images or PDFs to a Bluetooth ESC/POS thermal printer.",
    )
    parser.add_argument(
        "file", nargs="?", help="file to print; - or none reads stdin as text"
    )
    parser.add_argument(
        "-i", "--info", action="store_true", help="query the printer and exit"
    )
    parser.add_argument("-c", "--center", action="store_true", help="centre text lines")
    parser.add_argument(
        "-f",
        "--font",
        metavar="NAME|FILE",
        help="TTF/OTF file or fontconfig family name",
    )
    parser.add_argument(
        "-s",
        "--size",
        type=int,
        default=FONT_SIZE,
        metavar="PX",
        help="font size in pixels (default %(default)s)",
    )
    parser.add_argument(
        "-t",
        "--trim",
        action=argparse.BooleanOptionalAction,
        default=True,
        help="drop leading and trailing blank lines (default: on)",
    )
    parser.add_argument(
        "-z",
        "--feed",
        type=int,
        default=FEED_DOTS,
        metavar="DOTS",
        help="feed this many dots after the job (default %(default)s)",
    )
    parser.add_argument("--no-feed", action="store_true", help="send no feed at all")
    parser.add_argument(
        "--serve", action="store_true", help="hold the Bluetooth link (link holder)"
    )
    parser.add_argument("--mac", help="printer MAC address (default: $TP_MAC)")
    parser.add_argument(
        "--channel", type=int, help="RFCOMM channel (default: $TP_CHANNEL or 1)"
    )
    args = parser.parse_args(argv)

    mac = args.mac or mac
    channel = args.channel or channel
    feed_dots = 0 if args.no_feed else args.feed
    if not 0 <= feed_dots <= 255:
        parser.error("feed must be 0-255 dots")

    if not mac:
        parser.error("no printer address: pass --mac or set TP_MAC")

    if args.serve:
        serve(mac, channel)
        return 0

    if args.info:
        return print_info(mac, channel)

    if args.file in (None, "-"):
        text = sys.stdin.buffer.read().decode("utf-8", "replace")
        print_text(
            text,
            mac,
            channel,
            args.center,
            args.font,
            args.size,
            args.trim,
            feed_dots,
        )
        return 0

    with open(args.file, "rb") as handle:
        data = handle.read()

    try:
        img = open_image(data)
    except OSError:
        # Not an image Pillow can open: PDFs and plain text both go as text.
        print_job(
            data,
            mac,
            channel,
            args.center,
            args.font,
            args.size,
            args.trim,
            feed_dots,
        )
        return 0

    print_image(img, mac, channel, feed_dots)
    return 0


def main():
    mac = os.environ.get("TP_MAC")
    channel = int(os.environ.get("TP_CHANNEL", "1"))

    # CUPS invokes the backend by its URI-scheme name, with the device URI as
    # the first argument. --cups is for testing by hand.
    if os.path.basename(sys.argv[0]) == "thermal" or "--cups" in sys.argv[1:]:
        try:
            return cups(sys.argv, mac, channel)
        except (LowBattery, OSError, subprocess.CalledProcessError) as err:
            print(f"thermal: {err}", file=sys.stderr)
            return 1

    try:
        return cli(sys.argv[1:], mac, channel)
    except (LowBattery, OSError, subprocess.CalledProcessError) as err:
        print(f"tp: {err}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    sys.exit(main())
