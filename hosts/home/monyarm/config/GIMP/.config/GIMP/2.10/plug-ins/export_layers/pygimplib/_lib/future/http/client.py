from __future__ import absolute_import

import sys

assert sys.version_info[0] < 3

from httplib import *

# These constants aren't included in __all__ in httplib.py:


# These are not available on Python 2.6.x:
try:
    from httplib import LineAndFileWrapper, LineTooLong
except ImportError:
    pass

# These may not be available on all versions of Python 2.6.x or 2.7.x
try:
    from httplib import (_MAXHEADERS, _MAXLINE, _METHODS_EXPECTING_BODY,
                         _is_illegal_header_value, _is_legal_header_name)
except ImportError:
    pass
