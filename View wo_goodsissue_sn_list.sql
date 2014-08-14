
CREATE VIEW [wo_goodsissue_sn_list]
AS
select 
X.U_belnrid
, X.U_belposid
, X.U_posid
, X.ItemCode
, X.serialnum
, sum(X.ibt1_quantity) quantity
from ( 
select 
ign1.U_belnrid
, ign1.U_belposid
, isnull(ign1.U_posid,0) U_posid
, oitm.ItemCode
,case when oitm.mansernum='Y' then osrn.distnumber else obtn.distnumber end as 'serialnum'
,itl1.quantity as 'ibt1_quantity' 
from ign1  
inner join oitl on oitl.doctype=59 and oitl.docentry=ign1.docentry and oitl.docline=ign1.linenum  
inner join itl1 on itl1.logentry=oitl.logentry  
left join obtn on obtn.itemcode=itl1.itemcode and obtn.sysnumber=itl1.sysnumber  
left join osrn on osrn.itemcode=itl1.itemcode and osrn.sysnumber=itl1.sysnumber  
inner join oitm on oitm.itemcode=itl1.itemcode  
left join beas_ftzuordnung serial on ign1.U_belnrid = serial.belnr_id  
and ign1.U_belposid = serial.belpos_id and serial.pos_id = ign1.U_posid  
and serial.from_item = osrn.DistNumber and oitl.docentry = serial.basedocentry 
and oitl.DocLine = serial.baseline 
left join beas_ftzuordnung batch on ign1.U_belnrid = batch.belnr_id 
and ign1.U_belposid = batch.belpos_id and batch.pos_id = ign1.U_posid 
and batch.from_item = obtn.DistNumber and oitl.docentry = batch.basedocentry 
and oitl.DocLine = batch.baseline 
where oitm.ManSerNum='Y' and ign1.U_belnrid is not null
union all 
select 
ige1.U_belnrid
, ige1.U_belposid
, isnull(ige1.U_posid,0) U_posid
, oitm.ItemCode
,case when oitm.mansernum='Y' then osrn.distnumber else obtn.distnumber end as 'serialnum'
,itl1.quantity as 'ibt1_quantity' 
from ige1 
inner join oitl on oitl.doctype=60 and oitl.docentry=ige1.docentry and oitl.docline=ige1.linenum  
inner join itl1 on itl1.logentry=oitl.logentry  
left join obtn on obtn.itemcode=itl1.itemcode and obtn.sysnumber=itl1.sysnumber  
left join osrn on osrn.itemcode=itl1.itemcode and osrn.sysnumber=itl1.sysnumber  
inner join oitm on oitm.itemcode=itl1.itemcode  
left join beas_ftzuordnung serial on ige1.U_belnrid = serial.belnr_id  
and ige1.U_belposid = serial.belpos_id and serial.pos_id = ige1.U_posid  
and serial.from_item = osrn.DistNumber and oitl.docentry = serial.basedocentry  
and oitl.DocLine = serial.baseline 
left join beas_ftzuordnung batch on ige1.U_belnrid = batch.belnr_id  
and ige1.U_belposid = batch.belpos_id and batch.pos_id = ige1.U_posid  
and batch.from_item = obtn.DistNumber and oitl.docentry = batch.basedocentry  
and oitl.DocLine = batch.baseline 
where oitm.ManSerNum='Y' and ige1.U_belnrid is not null
) X 
group by X.U_belnrid
, X.U_belposid
, X.U_posid
, X.ItemCode
, X.serialnum
having SUM(X.ibt1_quantity)<>0
GO


