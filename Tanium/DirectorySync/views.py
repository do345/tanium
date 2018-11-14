#D:\syncsvc\syncsvc\asset_sync\views.py
from django.shortcuts import render
from django.http import HttpResponse
from .models import Container 
import pyodbc

##Added for Exception & Logging##
import logging
import logging.handlers
#################################

def detail(request, ip)
    str = ip
    server = ‘tcp:52.79.199.106’ 
    database = ‘nbp_tanium’
    username = ‘nbp_tanium’
    password = ‘passw0rd’


#Added for Exception & Logging 
logger = logging.getLogger('synclogger')
fomatter = logging.Formatter('[%(levelname)s|%(filename)s:%(lineno)s] %(asctime)s > %(message)s')
fileHandler = logging.FileHandler('ErrorLog.log')
streamHandler = logging.StreamHandler()

fileHandler.setFormatter(fomatter)
streamHandler.setFormatter(fomatter)

logger.addHandler(fileHandler)
logger.addHandler(streamHandler)
logger.setLevel(logging.DEBUG)



#################################


##Added for Exception & Logging##
try:

#################################

    cnxn = pyodbc.connect('DRIVER={ODBC Driver 13 for SQL Server};SERVER='+server+';DATABASE='+database+';UID='+username+';PWD='+ password)

    cursor.execute( 'SELECT ASSET_ID, COMP_SHORT_NM, ORG_NM, EMPNO, EMPNM, ASSET_STATUS_NM, MANAGEMENT_TYPE_NM, MAC_1, MAC_2, MAC_3, MAC_4, MAC_5  FROM NBP_TANIUM WHERE MAC_1= ? Or MAC_2= ? Or MAC_3 = ? Or MAC_4 = ? Or MAC_5 = ? ', str, str, str, str, str)
    row = cursor.fetchone()


    ASSET_ID = row[0]
    COMP_SHORT_NM = row[1]
    ORG_NM = row[2]
    EMPNO = row[3]
    EMPNM = row[4]
    ASSET_STATUS_NM = row[5]
    MANAGEMENT_TYPE_NM = row[6]
    MAC_1 = row[7]
    MAC_2 = row[8]
    MAC_3 = row[9]
    MAC_4 = row[10]
    MAC_5  = row[11]
    dil = ','

##Added for Exception & Logging##
except Exception as err:
  error = err.args
  logger.error(error.message)

finally:
  cnxn.close()
#################################



    return HttpResponse(ASSET_ID + dil + COMP_SHORT_NM + dil + ORG_NM + dil + EMPNO + dil + EMPNM + dil + ASSET_STATUS_NM + dil + MANAGEMENT_TYPE_NM + dil + MAC_1 + dil + MAC_2 + dil + MAC_3 + dil + MAC_4 + dil + MAC_5 )
 