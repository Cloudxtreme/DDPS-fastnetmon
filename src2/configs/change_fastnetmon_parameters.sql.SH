--
-- Change with
--      cat change_fastnetmon_parameters.sql | sudo su postgres -c "cd /tmp; psql -d netflow "
--

UPDATE flow.fastnetmoninstances
    SET 
    -- notes:
    --      description e.g. 'M1 E2, contact NTH or NIE'
    notes = '${notes}',
    networks_list = '${NETWORKS_LIST}',
    -- mode:
    --      accept, discard, accept or rate-limit 9600
    --      accept: monitor only -- creating dummy rules
    mode = 'discard',
    networks_whitelist = '130.225.242.200/29 130.225.245.208/29',
    blocktime = '10',
    process_incoming_traffic = 'on',
    process_outgoing_traffic = 'off',
    ban_time = '10',
    threshold_pps = '20000',
    threshold_mbps = '1000',
    threshold_flows = '3500',
    threshold_tcp_mbps = '10000',
    threshold_udp_mbps = '10000',
    threshold_icmp_mbps = '10000',
    threshold_tcp_pps = '10000',
    threshold_udp_pps = '10000',
    threshold_icmp_pps = '10000',
    ban_for_tcp_bandwidth = 'on',
    ban_for_udp_bandwidth = 'on',
    ban_for_icmp_bandwidth = 'on',
    ban_for_tcp_pps = 'on',
    ban_for_udp_pps = 'on',
    ban_for_icmp_pps = 'on',
    status = '${status}'
WHERE $SEARCH = '${QUERY}';

