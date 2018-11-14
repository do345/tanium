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
import rec_db_query
from tanium.sensor_io import sensor_output



def process_user_inputs(inputs):
    """Processes user inputs (via Tanium Console) and sets the SQL query statement"""
    # Remove this code block after customers upgrade past Trace 2.5.X
    import time
    time_range = util.unescape(inputs.time_range)
    abs_time_range = util.unescape(inputs.abs_time_range)
    if time_range == '30 minutes':
        time_range = 'absolute time range'
        abs_time_range = '{}|{}'.format((int(time.time()) - 30 * 60) * 1000, int(time.time()) * 1000)

    # User input String values via Tanium Console
    start_time, end_time = utils.get_time_range(time_range, abs_time_range)
    file_path = util.unescape(inputs.file_path)
    operation = util.unescape(inputs.operation)
    process_path = util.unescape(inputs.process_path)
    domain = util.unescape(inputs.domain)
    username = util.unescape(inputs.username)

    rdbq = rec_db_query.RecorderDatabaseQuery(treat_as_regex, make_stackable, unstackable_columns_to_skip)
    rdbq.max_query_rows = 1 if inputs.max_results_per_host == '' else int(util.unescape(inputs.max_results_per_host))

    query_values = [
        rec_db_query.QueryValue(val=start_time, used_in_regexp=False),
        rec_db_query.QueryValue(val=end_time, used_in_regexp=False),
    ]
    qv_operation = rec_db_query.QueryValue(val=operation, used_in_regexp=True)
    qv_file_path = rec_db_query.QueryValue(val=file_path, used_in_regexp=True)
    qv_process_path = rec_db_query.QueryValue(val=process_path, used_in_regexp=True)
    qv_domain = rec_db_query.QueryValue(val=domain, used_in_regexp=True)
    qv_username = rec_db_query.QueryValue(val=username, used_in_regexp=True)

    rdbq.set_sql_statement(
        statement='SELECT DISTINCT'
        ' timestamp,'
        ' file,'
        ' operation,'
        ' process_name,'
        ' domain,'
        ' username '
        ' FROM FileSummary WHERE'
        ' timestamp_raw >= ? AND timestamp_raw <= ? {0}{1}{2}{3}{4} '
        ' ORDER BY timestamp_raw DESC'.format(
            rdbq.gen_sql_phrase('AND', 'operation', qv_operation, query_values),
            rdbq.gen_sql_phrase('AND', 'file', qv_file_path, query_values),
            rdbq.gen_sql_phrase('AND', 'process_name', qv_process_path, query_values),
            rdbq.gen_sql_phrase('AND', 'domain', qv_domain, query_values),
            rdbq.gen_sql_phrase('AND', 'username', qv_username, query_values),
        ),
        query_values=query_values,
    )
    return rdbq


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

    db_over_config_max(db_path, _max_size_exceeded_slop_percentage, results)

    process_user_inputs(parsed_args)

    DatabaseCreationDate()
    DatabaseOldestItemDate()

    NumberOfIncreasedItemsByDay(1)
    NumberOfIncreasedItemsByDay(7)
    NumberOfIncreasedItemsByDay(30)


    return results


if __name__ == '__main__':
    tanium.run_sensor(main)

END_DELIM = str('no-op')
END_DELIM
