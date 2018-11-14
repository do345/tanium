import math
import os
import tanium
import utils
from tanium import client
import rec_db_query
from tanium.sensor_io import sensor_output

def DatabaseCreationDate():

    rdbq = rec_db_query.RecorderDatabaseQuery()
    rdbq.max_query_rows = 1 
    max_lines = 1

    rdbq.set_sql_statement(
        statement='SELECT HEX(info_value) FROM SystemInformation WHERE info_name={0}'.format('CreateDate'),
    )

    rdbq.cleanup_sql_result_row = utils.cleanup_sql_result_row
    rdbq.do_query(0)

    results = []
    for line in rdbq.get_result_line():
        if len(results) < max_lines and line not in results:
            results.append(line)
        else:
            break

    return results

def DatabaseOldestItemDate():

    rdbq = rec_db_query.RecorderDatabaseQuery()
    rdbq.max_query_rows = 1 
    max_lines = 1

    rdbq.set_sql_statement(
        statement='SELECT HEX(timestamp) FROM CombinedEventsSummary Limit 1',
        ,
    )

    rdbq.cleanup_sql_result_row = utils.cleanup_sql_result_row
    rdbq.do_query(0)

    results = []
    for line in rdbq.get_result_line():
        if len(results) < max_lines and line not in results:
            results.append(line)
        else:
            break

    return results

def NumberOfIncreasedItemsByDay(iDay):

    import time

    if iDay == 1 :       
        time_range = '1 day'
        abs_time_range = '{}|{}'.format((int(time.time()) - 60 * 60 * 24) * 1000, int(time.time()) * 1000)

    elif iDay == 7 :     
        time_range = '1 week' 
        abs_time_range = '{}|{}'.format((int(time.time()) - 60 * 60 * 24 * 7) * 1000, int(time.time()) * 1000)
    elif iDay == 30 :    
        time_range = '1 month'
        abs_time_range = '{}|{}'.format((int(time.time()) - 60 * 60 * 24 * 30) * 1000, int(time.time()) * 1000)

    time_range = util.unescape(time_range)
    abs_time_range = util.unescape(abs_time_range)

    # User input String values via Tanium Console
    start_time, end_time = utils.get_time_range(time_range, abs_time_range)


    query_values = [
        rec_db_query.QueryValue(val=start_time, used_in_regexp=False),
        rec_db_query.QueryValue(val=end_time, used_in_regexp=False),
    ]

    rdbq = rec_db_query.RecorderDatabaseQuery()
    rdbq.max_query_rows = 1 
    max_lines = 1

    rdbq.set_sql_statement(
        statement='SELECT HEX(count(id)) FROM CombinedEventsSummary WHERE timestamp_raw >= ? AND timestamp_raw <= ?',
        query_values=query_values,
    )

    rdbq.cleanup_sql_result_row = utils.cleanup_sql_result_row
    rdbq.do_query(0)

    results = []
    for line in rdbq.get_result_line():
        if len(results) < max_lines and line not in results:
            results.append(line)
        else:
            break

    return results




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
    #db_path = os.path.join(client.get_client_dir('Tools/Trace'), 'monitor.db')

    #results = []
    #_max_size_exceeded_slop_percentage = 10  # allows for some temporary overage

    #db_over_config_max(db_path, _max_size_exceeded_slop_percentage, results)

    result1 = DatabaseCreationDate()
    result2 = DatabaseOldestItemDate()

    result3 = NumberOfIncreasedItemsByDay(1)
    result4 = NumberOfIncreasedItemsByDay(7)
    result5 = NumberOfIncreasedItemsByDay(30)



    return '{0}|{1}|{2}|{3}|{4}'.format(result1,result2,result3,result4,result5)


