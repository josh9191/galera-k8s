#!/bin/bash

# currently, data directory is fixed
DATA_DIR='/var/lib/mysql'

# sleep until mysqld startup(without password)
sleep_until_mysqld_startup() {
    local success=F
    echo "Trying to connect MariaDB..."
    for t in $(seq 1 180); do
        mysql -h localhost -u root -e "SELECT 1"
        if [ "$?" = "0" ]; then
            success=T
            break
        fi
        echo "MariaDB not started. Pending..."
        sleep 1
    done
    # failed
    if [ "$success" = "F" ]; then
        echo "mysqld failed to start."
        exit 1
    fi
}

if [ "" = "$MARIADB_CLUSTER_NAME" ]; then
    echo "Please, set MARIADB_CLUSTER_NAME environment variable." exit 1;
fi

# add galera configuarion to /etc/mysql/my.cnf
# if first cluster - add_galera_conf T
# else - add_galera_conf F 192.168.0.1,192.168.0.2
add_galera_conf() {
    local is_first_cluster=$1
    local cluster_addr=
    if [ "F" = "$is_first_cluster" ]; then
        cluster_addr=gcomm://$2
    else
        cluster_addr=gcomm://
    fi

    cat >> /etc/mysql/my.cnf << EOF
        [galera]
        wsrep_on=ON
        wsrep_provider=/usr/lib/galera/libgalera_smm.so
        wsrep_cluster_address=${cluster_addr}
        wsrep_cluster_name=${MARIADB_CLUSTER_NAME}
        wsrep_node_address=$(resolveip -s $HOSTNAME)
        wsrep_node_name=${HOSTNAME}
        wsrep_sst_method=mysqldump
        wsrep_sst_auth=root:${MYSQL_ROOT_PASSWORD}
        wsrep_debug=SERVER
        binlog_format=row
        default_storage_engine=InnoDB
        innodb_autoinc_lock_mode=2
        bind-address=0.0.0.0
EOF
}

# change ownership
find "$DATA_DIR" \! -user mysql -exec chown mysql '{}' \;

# if the data directory does not exist, newly install it
if [ ! -d "$DATA_DIR/mysql" ]; then
    mysql_install_db --datadir="$DATA_DIR" --auth-root-authentication-method=normal
    mysqld &
    # mysqld_safe --skip-grant-tables &
    sleep_until_mysqld_startup
    read -r -d '' create_root_query << EOF
        CREATE USER 'root'@'%' IDENTIFIED BY "${MYSQL_ROOT_PASSWORD}";
        GRANT ALL PRIVILEGES ON *.* TO 'root'@'%' WITH GRANT OPTION;
        FLUSH PRIVILEGES;
EOF
    mysql -u root -e "${create_root_query}"
    mysqladmin -u root shutdown
fi


# enable clustering
if [ "" = "${MULTI_POD_ENABLED}" ]; then
    echo "Please, set MULTI_POD_ENABLED environment variable."
    exit 1;
elif [ "T" = "${MULTI_POD_ENABLED}" ]; then
    if [ "" = "${SERVICE_NAME}" ]; then
        echo "Please, set SERVICE_NAME environment variable."
        exit 1;
    fi
    # sleep 30 seconds to successfully discover the previous pods
    echo "Sleep for a while...(30 seconds)"
    sleep 30
    # service discovery using perl file
    srv_result=$(perl /svc-discovery.pl $SERVICE_NAME)
    case "${srv_result}" in
        # case 1. this pod is the first running one
        "")
            echo "There is no running pod..."
            # [FIXME] force boostrap or not
            # rm -f /var/lib/mysql/galera.cache /var/lib/mysql/grastate.dat
            add_galera_conf T
            mysqld --wsrep-new-cluster
        ;;
        # case 2. already has running pod
        *)
            echo "There is already running pod..."
            add_galera_conf F ${srv_result}
            mysqld
        ;; 
    esac
else
    # although MULTI_POD_ENABLED = F, use singe cluster mode
    echo "Sleep for a while...(5 seconds)"
    sleep 5
    add_galera_conf T
    mysqld --wsrep-new-cluster
fi

echo "Cluster setup has been finished. Start MariaDB server..."
