/*
  Report ID: beas_QC_RPT_001
  Title: GRPO Inspection result detail
  Path: BEAS > Quality Control > Reports Quality Control
*/
select 
  cast(year(t2.produziert_am) as varchar)+'-'+cast(month(t2.produziert_am) as varchar)+'-'+cast(day(t2.produziert_am) as varchar) [单据日期]
  , t2.itemcode [产品编号]
  , t2.bez [描述]
  , t2.charge_id [单据编号]
  , t2.u_beas_ver [配方号]
  , t2.znr [图号]
  , t2.bewertunginfo [备注]
  , t3.knd_id [抽样次数]
  , case t3.pruefkz when 'E' then '阻止' when 'F' then '解锁' else '打开' end [检测结果]
  , t4.pos_id [编号]
  , t4.qs_id [检测项目]
  , t4.bez [检测方法]
  , t4.sollwert [期望值]
  , t4.messwert [实测值]
  , case t4.ok when 'J' then '通过' else '阻止' end [通过]
  , t4.sperrgrundid [阻止编号]
  , t4.sperrgrund [阻止原因]
from beas_qsfthaupt t2
left join beas_qsftmessung t3 on t2.charge_id=t3.charge_id and t3.belnr_id=t2.belnr_id
left join beas_qsftpos t4 on t3.charge_id=t4.charge_id and t3.knd_id=t4.knd_id and t3.belnr_id=t4.belnr_id
where t2.typ='W' and t2.produziert_am between '<begDate>' and '<endDate>'