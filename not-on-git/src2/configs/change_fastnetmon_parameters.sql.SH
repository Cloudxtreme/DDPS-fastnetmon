--
-- Change with
--      cat change_fastnetmon_parameters.sql | sudo su postgres -c "cd /tmp; psql -d netflow "
--

UPDATE flow.fastnetmoninstances
    SET 
    -- notes:
    --      description e.g. 'M1 E2, contact NTH or NIE'
    notes = '${notes}',
    networks_list = '${networks_list}',
    -- mode:
    --      accept, discard, accept or rate-limit 9600
    --      accept: monitor only -- creating dummy rules
    mode = '${mode}',
    networks_whitelist = '${networks_whitelist}',
    blocktime = '${blocktime}',
    process_incoming_traffic = '${process_incoming_traffic}',
    process_outgoing_traffic = '${process_outgoing_traffic}',
    ban_time = '${ban_time}',
    threshold_pps = '${threshold_pps}',
    threshold_mbps = '${threshold_mbps}',
    threshold_flows = '${threshold_flows}',
    threshold_tcp_mbps = '${threshold_tcp_mbps}',
    threshold_udp_mbps = '${threshold_udp_mbps}',
    threshold_icmp_mbps = '${threshold_icmp_mbps}',
    threshold_tcp_pps = '${threshold_tcp_pps}',
    threshold_udp_pps = '${threshold_udp_pps}',
    threshold_icmp_pps = '${threshold_icmp_pps}',
    ban_for_tcp_bandwidth = '${ban_for_tcp_bandwidth}',
    ban_for_udp_bandwidth = '${ban_for_udp_bandwidth}',
    ban_for_icmp_bandwidth = '${ban_for_icmp_pps}',
    ban_for_tcp_pps = '${ban_for_tcp_pps}',
    ban_for_udp_pps = '${ban_for_udp_pps}',
    ban_for_icmp_pps = '${ban_for_icmp_pps}',
    status = '${status}'
WHERE $SEARCH = '${QUERY}';

