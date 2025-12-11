#!/usr/bin/env python
import os
import shutil
import subprocess
import tempfile
import urllib

import urlparse

BINARY="""/mnt/mediaSSD/Bethesda/Tools/Texconv//texconv.exe"""

# https://stackoverflow.com/questions/11687478/convert-a-filename-to-a-file-url
def path2url(path):
    return urlparse.urljoin(
      'file:', urllib.pathname2url(path))

from gimpfu import *


def save_dds_texconv(img, drawable, filename, raw_filename):
    tmp = tempfile.mkdtemp("-gimp-dds-save")
    name = os.path.splitext(os.path.basename(filename))[0]
    try:
        savePath = tmp + '\\' + name + '.png'
        pdb['file-png-save-defaults'](img, drawable, savePath, path2url(savePath))
        #pdb.gimp_message("Save path: " + savePath)
        codec="BC7_UNORM"
        if "_cm" in name.lower():
            codec="BC7_UNORM_SRGB"
        run_smart(["wine",BINARY, "-y", "-ft", "DDS", "-f", codec, "-o", tmp, savePath])
        result = tmp + '\\' + name + '.dds'
        #pdb.gimp_message('result file ' + result)
        if os.path.isfile(result):
            if os.path.isfile(filename):
                os.remove(filename)
            shutil.move(result, filename)
        else:
            pdb.gimp_message("failed to save DDS")
    except Exception as ex:
        pdb.gimp_message("Exception:\n" + str(ex))
    finally:
        shutil.rmtree(tmp)

    return None

def run_smart(args):
    try:
        argline = " ".join(["\"" + x + "\"" for x in args])
        #pdb.gimp_message("run: " + argline)
        subprocess.check_call(args)
    except Exception as ex:
        pdb.gimp_message("Error: " + str(ex))

def load_dds_texconv(filename, raw_filename):
    tmp = tempfile.mkdtemp("-gimp-dds-load")
    name = os.path.splitext(os.path.basename(filename))[0]
    try:
        result = tmp + '\\' + name + '.png'
        #pdb.gimp_message(result)
        run_smart(["wine",BINARY, "-ft", "PNG", "-o", tmp, filename])
        #pdb.gimp_message('load ' + result)
        return pdb['file-png-load'](result, path2url(result))
    except Exception as ex:
        pdb.gimp_message("Exception:\n" + str(ex))
    finally:
        shutil.rmtree(tmp)

    return None

def register_load_handlers():
    gimp.register_load_handler('file-dds-texconv-load', 'dds', '')
    pdb['gimp-register-file-handler-mime']('file-dds-texconv-load', 'image/vnd-ms.dds')

def register_save_handlers():
    gimp.register_save_handler('file-dds-texconv-save', 'dds', '')

register(
    'file-dds-texconv-save',
    'save a DDS file with texconv',
    'save a DDS file with texconv',
    'Westin Miller',
    'Westin Miller',
    '2018',
    'DDS',
    '*',
    [
        (PF_IMAGE, "image", "Input image", None),
        (PF_DRAWABLE, "drawable", "Input drawable", None),
        (PF_STRING, "filename", "The name of the file", None),
        (PF_STRING, "raw-filename", "The name of the file", None),
    ],
    [],
    save_dds_texconv,
    on_query = register_save_handlers,
    menu = '<Save>'
)

register(
    'file-dds-texconv-load',
    'load a DDS file with texconv',
    'load a DDS file with texconv',
    'Westin Miller',
    'Westin Miller',
    '2018',
    'DDS',
    None,
    [
        (PF_STRING, 'filename', 'The name of the file to load', None),
        (PF_STRING, 'raw-filename', 'The name entered', None),
    ],
    [(PF_IMAGE, 'image', 'Output image')],
    load_dds_texconv,
    on_query = register_load_handlers,
    menu = "<Load>",
)


main()
