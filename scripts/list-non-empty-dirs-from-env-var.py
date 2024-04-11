import os

KEY = "XDG_DATA_DIRS"
xdg_data_dirs = os.environ.get(KEY)
if not isinstance(xdg_data_dirs, str): raise TypeError(f"{KEY} is not a string")

xdg_data_dirs = xdg_data_dirs.split(':')

for path in xdg_data_dirs:
    try:
        ls = os.listdir(path)
        if len(ls) > 0:
            print(path)
    except: pass
