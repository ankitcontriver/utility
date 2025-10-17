Create Table: CREATE TABLE `pa_tenant_mapping` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `msc_ip` varchar(20) DEFAULT NULL,
  `operator` varchar(10) NOT NULL,
  `country` varchar(10) NOT NULL,
  `long_code` varchar(20) NOT NULL,
  `b_party_param` varchar(30) NOT NULL,
  PRIMARY KEY (`id`)
)
