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
import pre_run_checks as amod  # amod = arbitrary_module
amod.saved_question_name = 'trace_file_operations.py'
amod.saved_question_version = '2.7.3.0004'

import argparse
import rec_db_query
import tanium
import utils
from tanium import util
from tanium.sensor_io import sensor_output


def process_user_inputs(inputs):
    """Processes user inputs (via Tanium Console) and sets the SQL query statement"""
    # User input Boolean values via Tanium Console
    treat_as_regex = int(util.unescape(inputs.treat_as_regex)) == 1
    make_stackable = int(util.unescape(inputs.make_stackable)) == 1
    unstackable_columns_to_skip = ('timestamp', 'domain', 'username')

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


def parse_args():
    """Parses command line arguments"""
    parser = argparse.ArgumentParser()
    parser.add_argument('-t', '--time_range', default='||TimeRange||')
    parser.add_argument('-a', '--abs_time_range', default='||AbsoluteTimeRange||')
    parser.add_argument('-r', '--treat_as_regex', default='||TreatInputAsRegEx||')
    parser.add_argument('-o', '--only_yes_or_no', default='||OutputYesOrNoFlag||')
    parser.add_argument('-s', '--make_stackable', default='||MakeStackable||')
    parser.add_argument('-f', '--file_path', default='||FilePath||')
    parser.add_argument('-O', '--operation', default='||Operation||')
    parser.add_argument('-p', '--process_path', default='||ProcessPath||')
    parser.add_argument('-D', '--domain', default='||Domain||')
    parser.add_argument('-u', '--username', default='||Username||')
    parser.add_argument('-m', '--max_results_per_host', default='||MaxResultsPerHost||')
    return parser.parse_args()
    # Test string: -t 'unlimited' -a '' -r 0 -o 0 -s 0 -f '' -O '' -p '' -D '' -u '' -m 10


def main(parsed_args, max_lines=tanium.MAX_RESULTS):
    ttq = process_user_inputs(parsed_args)
    ttq.cleanup_sql_result_row = utils.cleanup_sql_result_row
    ttq.prepend_endpoint_name = True
    ttq.do_query(0)

    results = []
    for line in ttq.get_result_line():
        if len(results) < max_lines and line not in results:
            results.append(line)
        else:
            break
    return results


if __name__ == '__main__':
    args = parse_args()
    if int(util.unescape(args.only_yes_or_no)) == 1:
        tanium.run_sensor(main, main_func_args={'parsed_args': args}, custom_output_class=sensor_output.HasOutput())
    else:
        tanium.run_sensor(main, main_func_args={'parsed_args': args})

END_DELIM = str('no-op')
END_DELIM
