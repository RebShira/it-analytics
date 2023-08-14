import sqlalchemy as sa
import pandas as pd
import json
import sys


def run_command(**kwargs):
    server = 'EMPHSQLCLONE'
    database = 'ITAnalytics'
    engine = sa.create_engine(
        'mssql+pyodbc://' + server + '/' + database + '?trusted_connection=yes&driver=ODBC+Driver+17+for+SQL+Server')
    conn = engine.connect()

    ref = 'SELECT id, store_type, store_domain, batch_sequence, ' \
          'store_name, store_description, store_database, store_sql, num_args ' \
          'FROM analytics_datastores WHERE '

    # Get required parameter WHERE clause from **kwargs.
    param_found = False
    record_param = ''
    for key in kwargs:
        if key == 'ID':
            get_value = str(kwargs['ID'])
            record_param = 'ID = ' + get_value
            ref += f'id = {get_value}'
            param_found = True
            break
        elif key == 'Name':
            get_value = '\'' + kwargs['Name'] + '\''
            record_param = 'Name = ' + get_value
            ref += f'store_name = {get_value}'
            param_found = True
            break
    if not param_found:
        return ['ERROR: Need to supply a Keyword Argument of either a Data Store ID or "Name"']

    # Get the recordset from datastores to process...
    sql = pd.read_sql(ref, conn)

    # Does the record actually exist?
    if sql.empty:
        return

    # Is this record actually a stored proc call?
    check_value = str((sql.at[0, 'store_type']))
    if check_value != 'C':
        return

    # All considered, good to go...
    command = str(sql.at[0, 'store_sql'])
    conn.execute(command)


def return_dataset(**kwargs):
    server = 'EMPHSQLCLONE'
    database = 'ITAnalytics'
    engine = sa.create_engine(
        'mssql+pyodbc://' + server + '/' + database + '?trusted_connection=yes&driver=ODBC+Driver+17+for+SQL+Server')
    conn = engine.connect()
    ref = 'SELECT id, store_type, store_domain, batch_sequence, ' \
          'store_name, store_description, store_database, store_sql, num_args '\
          'FROM analytics_datastores WHERE '

    ref2 = 'SELECT param_name, param_type, param_size '\
           'FROM analytics_datastores_parameters WHERE fk_datastores = '

    # Get parameter WHERE clause from **kwargs
    param_found = False
    record_param = ''
    for key in kwargs:
        if key == 'ID':
            get_value = str(kwargs['ID'])
            record_param = 'ID = ' + get_value
            ref += f'id = {get_value}'
            param_found = True
            break
        elif key == 'Name':
            get_value = '\'' + kwargs['Name'] + '\''
            record_param = 'Name = ' + get_value
            ref += f'store_name = {get_value}'
            param_found = True
            break
    if not param_found:
        return ['ERROR: Need to supply a Keyword Argument of either a Data Store ID or "Name"']

    # Get the recordset from datastores to process...
    sql = pd.read_sql(ref, conn)

    # Get the necessary dataset, and return it in the requested format (default = json):
    format_found = False
    dataset = False
    get_value = ''
    for key in kwargs:
        if key == 'Format':
            get_value = kwargs['Format']
            format_found = True
        elif key == 'Data':
            dataset = True

    # Before anything else: Does the record actually exist? If not, return in format supplied
    # as an argument (if any)
    if sql.empty:
        return_val = ['ERROR: There is no record in datastores for ' + record_param + '.']
        sql = pd.DataFrame(return_val)
        if format_found:
            if get_value.lower() == 'dataset':
                return sql
            elif get_value.lower() == 'pandas':
                return sql
            elif get_value.lower() == 'numpy':
                return sql.to_numpy()
            elif get_value.lower() == 'dict':
                return sql.to_dict()
            else:
                return __create_json(sql)
        else:
            return __create_json(sql)

    # Is this "really" a dataset? It could be a call to run a stored procedure.
    # This potentially could be a runtime error, since a dataset of some sort
    # is expected here. So a fake recordset should be returned that states the issue.
    cmd_call = False
    check_value = str((sql.at[0, 'store_type']))
    if check_value == 'C':
        cmd_call = True

    if dataset:
        if cmd_call:
            return_val = ['Datastore record "' + record_param + ' is a command call! ' + \
                          'Use data_interactions.run_command(**kwargs) instead.']
            sql = pd.DataFrame(return_val)
        else:

            # Evaluate sql for parameters. param_name from related param table should match key in kwargs[]
            my_store_sql = sql.at[0, 'store_sql']
            param_count = sql.at[0, 'num_args']

            if param_count > 0:
                ref2 += str(sql.at[0, 'id'])
                sql_params = pd.read_sql(ref2, conn)
                # Make sure number of records returned matches the param_count...
                if len(sql_params.index) != param_count:
                    return [f'ERROR: Number of param records do not match expected ({param_count})']
                # Make sure the required parameters are in **kwargs...

                for i in range(param_count):
                    param_name = sql_params.at[i, 'param_name']
                    param_found = False
                    param_value = ''
                    for key in kwargs:
                        if key == param_name:
                            param_value = str(kwargs[key])
                            param_found = True
                    if not param_found:
                        return [
                            f'ERROR: Function call is missing keyword argument for required parameter "{param_name}"']
                    else:
                        # Check if what type of value it is, and if applicable, whether it meets a length requirement.
                        size = sql_params.at[i, 'param_size']
                        if size > 0:
                            if len(param_value) > size:
                                return [
                                    f'ERROR: Value argument for "{param_name}" exceeds parameter size limit ({size})']
                        data_type = sql_params.at[i, 'param_type']
                        if (data_type == 'CHAR') or (data_type == 'VARCHAR'):
                            replace_str = '\'' + param_value + '\''
                        else:
                            replace_str = param_value
                        my_store_sql = my_store_sql.replace(param_name, replace_str)

                sql.at[0, 'store_sql'] = my_store_sql

            np = sql.to_numpy()
            database = np[0, 6]
            datasql = np[0, 7]
            engine = sa.create_engine(
                'mssql+pyodbc://' + server + '/' + database +
                '?trusted_connection=yes&driver=ODBC+Driver+17+for+SQL+Server')
            conn = engine.connect()
            sql = pd.read_sql(datasql, conn)

    if format_found:
        if get_value.lower() == 'dataset':
            return sql
        elif get_value.lower() == 'pandas':
            return sql
        elif get_value.lower() == 'numpy':
            return sql.to_numpy()
        elif get_value.lower() == 'dict':
            return sql.to_dict()
        else:
            return __create_json(sql)
    else:
        return __create_json(sql)


def update_data():
    pass


def __create_json(dframe):
    records = dframe.reset_index().to_json(orient='records')
    json_obj = []
    json_obj = json.loads(records)
    return json_obj


def test_return_dataset():
    servers = return_dataset(ID=9, Format='dict', Data=True, Amp='2002')
    print(servers)


def test_run_command():
    run_command(ID=2)


# test_return_dataset()
