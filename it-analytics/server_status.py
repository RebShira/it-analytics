import sqlalchemy as sa
import pandas as pd
import concurrent.futures
import subprocess


def server_status(sql):
    def __get_server_status(ip):

        ping = subprocess.Popen(["ping", ip], stdout=subprocess.PIPE, stderr=subprocess.PIPE)
        out, error = ping.communicate()
        return_code = str(out).find('Destination host unreachable')
        if return_code == -1:
            return 'Online'
        else:
            return 'OFFLINE'

    def get_users_on_server(hostname, count_only=False):
        args = ['\\\\' + hostname + '\\C$\\Windows\\system32\\query.exe', 'user']
        process = subprocess.Popen(args, stdout=subprocess.PIPE)
        output, err = process.communicate()
        # TODO: With output as string, create logic that will count users.
        #  (maybe even have option to return them as a list?)
        if count_only:
            return str(0)
        else:
            return str(0)

    # Get the server data.

    # Evaluate server status, by server_type.
    # column_names = ['SERVERTYPE', 'SERVER', 'IP_ADDRESS', 'STATUS', 'CURR_ACTIVE_LOGONS']
    # TODO: Change below to update our dataFrame and convert it into a json file, to pass back to our template.
    results = []
    pings = []
    stypes = sql['server_type'].unique()
    for stype in stypes:
        sql_filter = sql[sql['server_type'] == stype]
        for index, row in sql_filter.iterrows():
            host = row['host_name']
            ip = row['ip_address']
            pings.append(row['ip_address'])
            if host == 'Terminal':
                curr_active_logons = get_users_on_server(hostname=host, count_only=True)
            else:
                curr_active_logons = 'N/A'
            results.append([str(stype), host, ip, curr_active_logons])

    # Use pings list to ping servers concurrently.
    with concurrent.futures.ThreadPoolExecutor() as executor:
        ping_results = executor.map(__get_server_status, pings)

    list_results = []
    for pr in ping_results:
        list_results.append(pr)
    loop = len(results)
    for i in range(loop):
        results[i].insert(3, list_results[i])

    return results
