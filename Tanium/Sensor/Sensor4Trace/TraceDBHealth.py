#!/bin/bash
# -*- coding: utf-8 -*-
#@INCLUDE=utils/python_preamble.sh
#@START_INCLUDES_HERE
#------------ INCLUDES START - Do not edit between this line and INCLUDE ENDS -----
#- Begin file: utils/python_preamble.sh
PYTHON_BINARY=Tools/Trace/python27/python
if [ ! -f "${PYTHON_BINARY}" ]; then
      echo "Trace Endpoint Tools not installed"
      exit 0
fi
"${PYTHON_BINARY}" - "$@" << END_DELIM
import os
import sys
py_content = os.path.join(os.getcwd(), 'Tools', 'Trace', 'content')
sys.path.append(py_content)
from pre_run_checks import pre_run_checks


errors = []
no_need_to_check_lib_versions = None
try:
    if not pre_run_checks(errors, '2.0.6', no_need_to_check_lib_versions):
        print('\n'.join(errors))
        exit()
except TypeError:
    try:
        if not pre_run_checks(errors, '2.0.6'):
            print('\n'.join(errors))
            exit()
    except TypeError:
        print('Error: Reinstall Trace Endpoint Tools, as pre_run_checks.py '
            'is out of date (minimum required version = 2.0.6)')
        exit()
#- End file: utils/python_preamble.sh
#------------ INCLUDES END - Do not edit above this line and INCLUDE STARTS -----
import math
import os
import tanium
import utils
from tanium import client


def get_range(value):
    if value == 0:
        return '0 - 100 MB'
    # Return a range with a width of 100 MB (e.g. 0 - 100 MB, 100 - 200 MB)
    bottom = int(math.floor(value / 100.) * 100)
    top = value + 100 if value % 100 == 0 else int(math.ceil(value / 100.) * 100)
    return '{0} - {1} MB'.format(bottom, top)


def db_over_config_max(db_path, slop_percentage, results):
    max_size_set_MB = utils.get_value_from_recorder_json('maxSizeMB', int)
    if max_size_set_MB is None:
        results.append('Warning: No maxSizeMB value set for Trace in recorder.json file')
        return
    current_size_MB = int(os.path.getsize(db_path)) / (1024 * 1024.)
    results.append('Info: Trace DB is {}'.format(get_range(current_size_MB)))
    results.append('Info: Trace Max DB Size is {} MB'.format(max_size_set_MB))
    return True if current_size_MB > max_size_set_MB * (100 + slop_percentage) / 100. else False


def main():
    db_path = os.path.join(client.get_client_dir('Tools/Trace'), 'monitor.db')

    results = []
    _max_size_exceeded_slop_percentage = 10  # allows for some temporary overage
    if db_over_config_max(db_path, _max_size_exceeded_slop_percentage, results):
        results.append('Error: Trace DB is greater than {0}% of configured maximum size'.format(
            _max_size_exceeded_slop_percentage + 100))
        results.append('Health Check Failed')
    else:
        results.append('Health Check Passed')
    return results


if __name__ == '__main__':
    tanium.run_sensor(main)

END_DELIM = str('no-op')
END_DELIM
