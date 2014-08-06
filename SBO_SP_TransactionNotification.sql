USE [TRP_TEST_01]
GO
/****** Object:  StoredProcedure [dbo].[SBO_SP_TransactionNotification]    Script Date: 08/05/2014 15:53:44 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
ALTER    PROC [dbo].[SBO_SP_TransactionNotification] 

@object_type NVARCHAR(20), 				-- SBO Object Type
@transaction_type NCHAR(1),			-- [A]dd, [U]pdate, [D]elete, [C]ancel, C[L]ose
@num_of_cols_in_key INT,
@list_of_key_cols_tab_del NVARCHAR(255),
@list_of_cols_val_tab_del NVARCHAR(255)

AS

BEGIN

-- Return values
DECLARE @error  INT				-- Result (0 for no error)
DECLARE @error_message NVARCHAR (200) 		-- Error string to be displayed
SELECT @error = 0
SELECT @error_message = N'Ok'

--------------------------------------------------------------------------------------------------------------------------------

--	ADD	YOUR	CODE	HERE
-- beasarea
-- beas-reservation-system. Do not replace or change this script
-- check if item is not reserverd
-- beas insert this auto-genereated script in the sap-procedure SBO_SP_Transaction
-- installation: with beas-object ue_installation.transactionnotification
-- By Martin Heigl, 2011/8/12
declare @beas_txt nvarchar(max),@beas_line nvarchar(100),@beas_unit nvarchar(20)
declare @beas_onhand decimal(19,6),@beas_quantity decimal(19,6),@beas_reserved decimal(19,6)
set @beas_txt=''
declare @ll_count int

-- ------------ Delivery -------------------
if (@object_type = '15') begin 
  -- Check negativ Stock on Bin-Warehouse
  select @ll_count= COUNT(*) from dln1   inner join oitw on oitw.itemcode = dln1.itemcode and oitw.whscode=dln1.whscode  
		inner join beas_whs on beas_whs.whscode=dln1.whscode and beas_whs.bintyp=1 where oitw.onhand < 0 and DocEntry=@list_of_cols_val_tab_del
  if @ll_count > 0
  begin
		  set @error_message='negative stock on a Bin-Warehouse is not allowed'
		  select @error = 500011
 end
 -- Check Reservation
  declare beas_delivery cursor for 
		select t1.itemcode+' Whs '+t1.whscode+' '+obtn.distnumber,itl1.quantity,obtq.quantity,
		isnull((select sum(r.quantity) from beas_reservation_line r where r.itemcode=t1.itemcode and r.whscode=t1.whscode and r.batchnum=obtn.distnumber and r.reservationtype='S' 
		and not(r.reservationtype='S' and r.base_type=convert(varchar(20),t1.basetype) and r.base_docentry=t1.baseentry and r.base_linenum2=t1.baseline)),0) as reservation,oitm.invntryuom
		 from dln1 t1  
		 inner join odln on odln.docentry=t1.docentry
		inner join oitm on oitm.itemcode=t1.itemcode and oitm.manbtchnum='Y' 
		inner join oitl on oitl.doctype=t1.objtype and oitl.docentry=t1.docentry and oitl.docline=t1.linenum
		inner join itl1 on itl1.logentry=oitl.logentry
		inner join obtq on obtq.itemcode=itl1.itemcode and obtq.sysnumber=itl1.sysnumber and obtq.whscode=t1.whscode
		inner join obtn on obtn.itemcode=itl1.itemcode and obtn.sysnumber=itl1.sysnumber
		where t1.docentry=@list_of_cols_val_tab_del and  isnull(odln.u_beas_version,'')=''
		union all
		select t1.itemcode+' '+t1.whscode+' '+osrn.distnumber+' ('+convert(varchar(20),osrn.sysnumber)+')',itl1.quantity,osrq.quantity,
		isnull((select sum(r.quantity) from beas_reservation_line r where r.itemcode=t1.itemcode and r.whscode=t1.whscode and r.batchnum=convert(varchar(20),osrn.sysnumber) and r.reservationtype='S' 
		and not(r.reservationtype='S' and r.base_type=convert(varchar(20),t1.basetype) and r.base_docentry=t1.baseentry and r.base_linenum2=t1.baseline)),0) as reservation,oitm.invntryuom
		 from dln1 t1  
		 inner join odln on odln.docentry=t1.docentry
		inner join oitm on oitm.itemcode=t1.itemcode and oitm.ManSerNum='Y' 
		inner join oitl on oitl.doctype=t1.objtype and oitl.docentry=t1.docentry and oitl.docline=t1.linenum
		inner join itl1 on itl1.logentry=oitl.logentry
		inner join osrq on osrq.itemcode=itl1.itemcode and osrq.sysnumber=itl1.sysnumber and osrq.whscode=t1.whscode
		inner join osrn on osrn.itemcode=itl1.itemcode and osrn.sysnumber=itl1.sysnumber
		where t1.docentry=@list_of_cols_val_tab_del and  isnull(odln.u_beas_version,'')=''
		union all
		select t1.itemcode+' Whs '+t1.whscode,t1.quantity,oitw.onhand,
		isnull((select sum(r.quantity) from beas_reservation_line r where r.itemcode=t1.itemcode and r.whscode=t1.whscode and (r.batchnum is null or r.batchnum='') and r.reservationtype='S' 
		and not(r.reservationtype='S' and r.base_type=convert(varchar(20),t1.basetype) and r.base_docentry=t1.baseentry and r.base_linenum2=t1.baseline)),0) as reservation,oitm.invntryuom
		 from dln1 t1  
		inner join odln on odln.docentry=t1.docentry
		inner join oitm on oitm.itemcode=t1.itemcode and oitm.manbtchnum='N'  and oitm.mansernum='N'
		inner join oitw on oitw.itemcode=t1.itemcode and oitw.whscode=t1.whscode
		where t1.docentry=@list_of_cols_val_tab_del and isnull(odln.u_beas_version,'')=''
	open beas_delivery
	fetch next from beas_delivery into @beas_line,@beas_quantity,@beas_onhand,@beas_reserved,@beas_unit
	while @@FETCH_STATUS = 0
	  begin
	  if (@beas_quantity > @beas_onhand + @beas_quantity - @beas_reserved ) and @beas_reserved > 0 begin
		  --The variable @beas_onHand has the new value of stock (Stock - quantity of the document)
		  set @beas_txt=@beas_txt +isnull(@beas_line,'')+' Free:'+convert(varchar(20),convert(decimal(19,2), @beas_onhand - @beas_reserved))+' '+isnull(@beas_unit,'') +',  '
		  select @error = 500000
		  end
	  
		  fetch next from beas_delivery into @beas_line,@beas_quantity,@beas_onhand,@beas_reserved,@beas_unit
	  end 
	close beas_delivery
	deallocate beas_delivery
	if @error = 500000 begin
      select @error_message='Reserved goods can not be charged: '+@beas_txt
    end
  end 

-- ------------ Invoice -------------------
if (@object_type = '13') begin 
  -- Check negativ Stock on Bin-Warehouse
  select @ll_count= COUNT(*) from inv1   inner join oitw on oitw.itemcode = inv1.itemcode and oitw.whscode=inv1.whscode  
		inner join beas_whs on beas_whs.whscode=inv1.whscode and beas_whs.bintyp=1 where oitw.onhand < 0 and DocEntry=@list_of_cols_val_tab_del
  if @ll_count > 0
  begin
		  set @error_message='negative stock on a Bin-Warehouse is not allowed'
		  select @error = 500011
 end
 -- Check Reservation
  declare beas_delivery cursor for 
		select t1.itemcode+' Whs '+t1.whscode+' '+obtn.distnumber,itl1.quantity,obtq.quantity,
		isnull((select sum(r.quantity) from beas_reservation_line r where r.itemcode=t1.itemcode and r.whscode=t1.whscode and r.batchnum=obtn.distnumber and r.reservationtype='S' 
		and not(r.reservationtype='S' and r.base_type=convert(varchar(20),t1.basetype) and r.base_docentry=t1.baseentry and r.base_linenum2=t1.baseline)),0) as reservation,oitm.invntryuom
		 from inv1 t1  
		 inner join oinv on oinv.docentry=t1.docentry
		inner join oitm on oitm.itemcode=t1.itemcode and oitm.manbtchnum='Y' 
		inner join oitl on oitl.doctype=t1.objtype and oitl.docentry=t1.docentry and oitl.docline=t1.linenum
		inner join itl1 on itl1.logentry=oitl.logentry
		inner join obtq on obtq.itemcode=itl1.itemcode and obtq.sysnumber=itl1.sysnumber and obtq.whscode=t1.whscode
		inner join obtn on obtn.itemcode=itl1.itemcode and obtn.sysnumber=itl1.sysnumber
		where t1.docentry=@list_of_cols_val_tab_del and  isnull(oinv.u_beas_version,'')=''
		union all
		select t1.itemcode+' '+t1.whscode+' '+osrn.distnumber+' ('+convert(varchar(20),osrn.sysnumber)+')',itl1.quantity,osrq.quantity,
		isnull((select sum(r.quantity) from beas_reservation_line r where r.itemcode=t1.itemcode and r.whscode=t1.whscode and r.batchnum=convert(varchar(20),osrn.sysnumber) and r.reservationtype='S' 
		and not(r.reservationtype='S' and r.base_type=convert(varchar(20),t1.basetype) and r.base_docentry=t1.baseentry and r.base_linenum2=t1.baseline)),0) as reservation,oitm.invntryuom
		 from inv1 t1  
		 inner join oinv on oinv.docentry=t1.docentry
		inner join oitm on oitm.itemcode=t1.itemcode and oitm.ManSerNum='Y' 
		inner join oitl on oitl.doctype=t1.objtype and oitl.docentry=t1.docentry and oitl.docline=t1.linenum
		inner join itl1 on itl1.logentry=oitl.logentry
		inner join osrq on osrq.itemcode=itl1.itemcode and osrq.sysnumber=itl1.sysnumber and osrq.whscode=t1.whscode
		inner join osrn on osrn.itemcode=itl1.itemcode and osrn.sysnumber=itl1.sysnumber
		where t1.docentry=@list_of_cols_val_tab_del and  isnull(oinv.u_beas_version,'')=''
		union all
		select t1.itemcode+' Whs '+t1.whscode,t1.quantity,oitw.onhand,
		isnull((select sum(r.quantity) from beas_reservation_line r where r.itemcode=t1.itemcode and r.whscode=t1.whscode and (r.batchnum is null or r.batchnum='') and r.reservationtype='S' 
		and not(r.reservationtype='S' and r.base_type=convert(varchar(20),t1.basetype) and r.base_docentry=t1.baseentry and r.base_linenum2=t1.baseline)),0) as reservation,oitm.invntryuom
		 from inv1 t1  
		inner join oinv on oinv.docentry=t1.docentry
		inner join oitm on oitm.itemcode=t1.itemcode and oitm.manbtchnum='N'  and oitm.mansernum='N'
		inner join oitw on oitw.itemcode=t1.itemcode and oitw.whscode=t1.whscode
		where t1.docentry=@list_of_cols_val_tab_del and isnull(oinv.u_beas_version,'')=''
	open beas_delivery
	fetch next from beas_delivery into @beas_line,@beas_quantity,@beas_onhand,@beas_reserved,@beas_unit
	while @@FETCH_STATUS = 0
	  begin
	  if (@beas_quantity > @beas_onhand + @beas_quantity - @beas_reserved ) and @beas_reserved > 0 begin
		  --The variable @beas_onHand has the new value of stock (Stock - quantity of the document)		  
		  set @beas_txt=@beas_txt +isnull(@beas_line,'')+' Free:'+convert(varchar(20),convert(decimal(19,2),@beas_onhand - @beas_reserved))+' '+isnull(@beas_unit,'') +',  '
		  select @error = 500000
		  end
	  
		  fetch next from beas_delivery into @beas_line,@beas_quantity,@beas_onhand,@beas_reserved,@beas_unit
	  end 
	close beas_delivery
	deallocate beas_delivery
	if @error = 500000 begin
      select @error_message='Reserved goods can not be charged: '+@beas_txt
    end
  end 

   -- ------------ Returns -------------------
   --We have to check this type of document because user can create Negative documents--
if (@object_type = '16') begin 
  -- Check negativ Stock on Bin-Warehouse
  select @ll_count= COUNT(*) from rdn1   inner join oitw on oitw.itemcode = rdn1.itemcode and oitw.whscode=rdn1.whscode  
		inner join beas_whs on beas_whs.whscode=rdn1.whscode and beas_whs.bintyp=1 where oitw.onhand < 0 and DocEntry=@list_of_cols_val_tab_del
  if @ll_count > 0
  begin
		  set @error_message='negative stock on a Bin-Warehouse is not allowed'
		  select @error = 500011
 end
 -- Check Reservation
  declare beas_delivery cursor for 
		select t1.itemcode+' Whs '+t1.whscode+' '+obtn.distnumber,itl1.quantity,obtq.quantity,
		isnull((select sum(r.quantity) from beas_reservation_line r where r.itemcode=t1.itemcode and r.whscode=t1.whscode and r.batchnum=obtn.distnumber and r.reservationtype='S' 
		and not(r.reservationtype='S' and r.base_type=convert(varchar(20),t1.basetype) and r.base_docentry=t1.baseentry and r.base_linenum2=t1.baseline)),0) as reservation,oitm.invntryuom
		 from rdn1 t1  
		 inner join ordn on ordn.docentry=t1.docentry
		inner join oitm on oitm.itemcode=t1.itemcode and oitm.manbtchnum='Y' 
		inner join oitl on oitl.doctype=t1.objtype and oitl.docentry=t1.docentry and oitl.docline=t1.linenum
		inner join itl1 on itl1.logentry=oitl.logentry
		inner join obtq on obtq.itemcode=itl1.itemcode and obtq.sysnumber=itl1.sysnumber and obtq.whscode=t1.whscode
		inner join obtn on obtn.itemcode=itl1.itemcode and obtn.sysnumber=itl1.sysnumber
		where t1.docentry=@list_of_cols_val_tab_del and  isnull(ordn.u_beas_version,'')=''
		union all
		select t1.itemcode+' '+t1.whscode+' '+osrn.distnumber+' ('+convert(varchar(20),osrn.sysnumber)+')',itl1.quantity,osrq.quantity,
		isnull((select sum(r.quantity) from beas_reservation_line r where r.itemcode=t1.itemcode and r.whscode=t1.whscode and r.batchnum=convert(varchar(20),osrn.sysnumber) and r.reservationtype='S' 
		and not(r.reservationtype='S' and r.base_type=convert(varchar(20),t1.basetype) and r.base_docentry=t1.baseentry and r.base_linenum2=t1.baseline)),0) as reservation,oitm.invntryuom
		 from rdn1 t1  
		 inner join ordn on ordn.docentry=t1.docentry
		inner join oitm on oitm.itemcode=t1.itemcode and oitm.ManSerNum='Y' 
		inner join oitl on oitl.doctype=t1.objtype and oitl.docentry=t1.docentry and oitl.docline=t1.linenum
		inner join itl1 on itl1.logentry=oitl.logentry
		inner join osrq on osrq.itemcode=itl1.itemcode and osrq.sysnumber=itl1.sysnumber and osrq.whscode=t1.whscode
		inner join osrn on osrn.itemcode=itl1.itemcode and osrn.sysnumber=itl1.sysnumber
		where t1.docentry=@list_of_cols_val_tab_del and  isnull(ordn.u_beas_version,'')=''
		union all
		select t1.itemcode+' Whs '+t1.whscode,t1.quantity,oitw.onhand,
		isnull((select sum(r.quantity) from beas_reservation_line r where r.itemcode=t1.itemcode and r.whscode=t1.whscode and (r.batchnum is null or r.batchnum='') and r.reservationtype='S' 
		and not(r.reservationtype='S' and r.base_type=convert(varchar(20),t1.basetype) and r.base_docentry=t1.baseentry and r.base_linenum2=t1.baseline)),0) as reservation,oitm.invntryuom
		 from rdn1 t1  
		inner join ordn on ordn.docentry=t1.docentry
		inner join oitm on oitm.itemcode=t1.itemcode and oitm.manbtchnum='N'  and oitm.mansernum='N'
		inner join oitw on oitw.itemcode=t1.itemcode and oitw.whscode=t1.whscode
		where t1.docentry=@list_of_cols_val_tab_del and isnull(ordn.u_beas_version,'')=''
	open beas_delivery
	fetch next from beas_delivery into @beas_line,@beas_quantity,@beas_onhand,@beas_reserved,@beas_unit
	while @@FETCH_STATUS = 0
	  begin
	  if (@beas_quantity > @beas_onhand + @beas_quantity - @beas_reserved ) and @beas_reserved > 0 begin
		  --The variable @beas_onHand has the new value of stock (Stock - quantity of the document)
		  set @beas_txt=@beas_txt +isnull(@beas_line,'')+' Free:'+convert(varchar(20),convert(decimal(19,2), @beas_onhand - @beas_reserved))+' '+isnull(@beas_unit,'') +',  '
		  select @error = 500000
		  end
	  
		  fetch next from beas_delivery into @beas_line,@beas_quantity,@beas_onhand,@beas_reserved,@beas_unit
	  end 
	close beas_delivery
	deallocate beas_delivery
	if @error = 500000 begin
      select @error_message='Reserved goods can not be charged: '+@beas_txt
    end
  end 

   -- ------------ AR Credit Note -------------------
   --We have to check this type of document because user can create Negative documents--
if (@object_type = '14') begin 
  -- Check negativ Stock on Bin-Warehouse
  select @ll_count= COUNT(*) from rin1   inner join oitw on oitw.itemcode = rin1.itemcode and oitw.whscode=rin1.whscode  
		inner join beas_whs on beas_whs.whscode=rin1.whscode and beas_whs.bintyp=1 where oitw.onhand < 0 and DocEntry=@list_of_cols_val_tab_del
  if @ll_count > 0
  begin
		  set @error_message='negative stock on a Bin-Warehouse is not allowed'
		  select @error = 500011
 end
 -- Check Reservation
  declare beas_delivery cursor for 
		select t1.itemcode+' Whs '+t1.whscode+' '+obtn.distnumber,itl1.quantity,obtq.quantity,
		isnull((select sum(r.quantity) from beas_reservation_line r where r.itemcode=t1.itemcode and r.whscode=t1.whscode and r.batchnum=obtn.distnumber and r.reservationtype='S' 
		and not(r.reservationtype='S' and r.base_type=convert(varchar(20),t1.basetype) and r.base_docentry=t1.baseentry and r.base_linenum2=t1.baseline)),0) as reservation,oitm.invntryuom
		 from rin1 t1  
		 inner join orin on orin.docentry=t1.docentry
		inner join oitm on oitm.itemcode=t1.itemcode and oitm.manbtchnum='Y' 
		inner join oitl on oitl.doctype=t1.objtype and oitl.docentry=t1.docentry and oitl.docline=t1.linenum
		inner join itl1 on itl1.logentry=oitl.logentry
		inner join obtq on obtq.itemcode=itl1.itemcode and obtq.sysnumber=itl1.sysnumber and obtq.whscode=t1.whscode
		inner join obtn on obtn.itemcode=itl1.itemcode and obtn.sysnumber=itl1.sysnumber
		where t1.docentry=@list_of_cols_val_tab_del and  isnull(orin.u_beas_version,'')=''
		union all
		select t1.itemcode+' '+t1.whscode+' '+osrn.distnumber+' ('+convert(varchar(20),osrn.sysnumber)+')',itl1.quantity,osrq.quantity,
		isnull((select sum(r.quantity) from beas_reservation_line r where r.itemcode=t1.itemcode and r.whscode=t1.whscode and r.batchnum=convert(varchar(20),osrn.sysnumber) and r.reservationtype='S' 
		and not(r.reservationtype='S' and r.base_type=convert(varchar(20),t1.basetype) and r.base_docentry=t1.baseentry and r.base_linenum2=t1.baseline)),0) as reservation,oitm.invntryuom
		 from rin1 t1  
		 inner join orin on orin.docentry=t1.docentry
		inner join oitm on oitm.itemcode=t1.itemcode and oitm.ManSerNum='Y' 
		inner join oitl on oitl.doctype=t1.objtype and oitl.docentry=t1.docentry and oitl.docline=t1.linenum
		inner join itl1 on itl1.logentry=oitl.logentry
		inner join osrq on osrq.itemcode=itl1.itemcode and osrq.sysnumber=itl1.sysnumber and osrq.whscode=t1.whscode
		inner join osrn on osrn.itemcode=itl1.itemcode and osrn.sysnumber=itl1.sysnumber
		where t1.docentry=@list_of_cols_val_tab_del and  isnull(orin.u_beas_version,'')=''
		union all
		select t1.itemcode+' Whs '+t1.whscode,t1.quantity,oitw.onhand,
		isnull((select sum(r.quantity) from beas_reservation_line r where r.itemcode=t1.itemcode and r.whscode=t1.whscode and (r.batchnum is null or r.batchnum='') and r.reservationtype='S' 
		and not(r.reservationtype='S' and r.base_type=convert(varchar(20),t1.basetype) and r.base_docentry=t1.baseentry and r.base_linenum2=t1.baseline)),0) as reservation,oitm.invntryuom
		 from rin1 t1  
		inner join orin on orin.docentry=t1.docentry
		inner join oitm on oitm.itemcode=t1.itemcode and oitm.manbtchnum='N'  and oitm.mansernum='N'
		inner join oitw on oitw.itemcode=t1.itemcode and oitw.whscode=t1.whscode
		where t1.docentry=@list_of_cols_val_tab_del and isnull(orin.u_beas_version,'')=''
	open beas_delivery
	fetch next from beas_delivery into @beas_line,@beas_quantity,@beas_onhand,@beas_reserved,@beas_unit
	while @@FETCH_STATUS = 0
	  begin
	  if (@beas_quantity > @beas_onhand + @beas_quantity - @beas_reserved ) and @beas_reserved > 0 begin
		  --The variable @beas_onHand has the new value of stock (Stock - quantity of the document)
		  set @beas_txt=@beas_txt +isnull(@beas_line,'')+' Free:'+convert(varchar(20),convert(decimal(19,2), @beas_onhand - @beas_reserved))+' '+isnull(@beas_unit,'') +',  '
		  select @error = 500000
		  end
	  
		  fetch next from beas_delivery into @beas_line,@beas_quantity,@beas_onhand,@beas_reserved,@beas_unit
	  end 
	close beas_delivery
	deallocate beas_delivery
	if @error = 500000 begin
      select @error_message='Reserved goods can not be charged: '+@beas_txt
    end
  end 

   
   -- ------------ Goods receipt PO -------------------
   --We have to check this type of document because user can create Negative documents--
if (@object_type = '20') begin 
  -- Check negativ Stock on Bin-Warehouse
  select @ll_count= COUNT(*) from pdn1   inner join oitw on oitw.itemcode = pdn1.itemcode and oitw.whscode=pdn1.whscode  
		inner join beas_whs on beas_whs.whscode=pdn1.whscode and beas_whs.bintyp=1 where oitw.onhand < 0 and DocEntry=@list_of_cols_val_tab_del
  if @ll_count > 0
  begin
		  set @error_message='negative stock on a Bin-Warehouse is not allowed'
		  select @error = 500011
 end
 -- Check Reservation
  declare beas_delivery cursor for 
		select t1.itemcode+' Whs '+t1.whscode+' '+obtn.distnumber,itl1.quantity,obtq.quantity,
		isnull((select sum(r.quantity) from beas_reservation_line r where r.itemcode=t1.itemcode and r.whscode=t1.whscode and r.batchnum=obtn.distnumber and r.reservationtype='S' 
		and not(r.reservationtype='S' and r.base_type=convert(varchar(20),t1.basetype) and r.base_docentry=t1.baseentry and r.base_linenum2=t1.baseline)),0) as reservation,oitm.invntryuom
		 from pdn1 t1  
		 inner join opdn on opdn.docentry=t1.docentry
		inner join oitm on oitm.itemcode=t1.itemcode and oitm.manbtchnum='Y' 
		inner join oitl on oitl.doctype=t1.objtype and oitl.docentry=t1.docentry and oitl.docline=t1.linenum
		inner join itl1 on itl1.logentry=oitl.logentry
		inner join obtq on obtq.itemcode=itl1.itemcode and obtq.sysnumber=itl1.sysnumber and obtq.whscode=t1.whscode
		inner join obtn on obtn.itemcode=itl1.itemcode and obtn.sysnumber=itl1.sysnumber
		where t1.docentry=@list_of_cols_val_tab_del and  isnull(opdn.u_beas_version,'')=''
		union all
		select t1.itemcode+' '+t1.whscode+' '+osrn.distnumber+' ('+convert(varchar(20),osrn.sysnumber)+')',itl1.quantity,osrq.quantity,
		isnull((select sum(r.quantity) from beas_reservation_line r where r.itemcode=t1.itemcode and r.whscode=t1.whscode and r.batchnum=convert(varchar(20),osrn.sysnumber) and r.reservationtype='S' 
		and not(r.reservationtype='S' and r.base_type=convert(varchar(20),t1.basetype) and r.base_docentry=t1.baseentry and r.base_linenum2=t1.baseline)),0) as reservation,oitm.invntryuom
		 from pdn1 t1  
		 inner join opdn on opdn.docentry=t1.docentry
		inner join oitm on oitm.itemcode=t1.itemcode and oitm.ManSerNum='Y' 
		inner join oitl on oitl.doctype=t1.objtype and oitl.docentry=t1.docentry and oitl.docline=t1.linenum
		inner join itl1 on itl1.logentry=oitl.logentry
		inner join osrq on osrq.itemcode=itl1.itemcode and osrq.sysnumber=itl1.sysnumber and osrq.whscode=t1.whscode
		inner join osrn on osrn.itemcode=itl1.itemcode and osrn.sysnumber=itl1.sysnumber
		where t1.docentry=@list_of_cols_val_tab_del and  isnull(opdn.u_beas_version,'')=''
		union all
		select t1.itemcode+' Whs '+t1.whscode,t1.quantity,oitw.onhand,
		isnull((select sum(r.quantity) from beas_reservation_line r where r.itemcode=t1.itemcode and r.whscode=t1.whscode and (r.batchnum is null or r.batchnum='') and r.reservationtype='S' 
		and not(r.reservationtype='S' and r.base_type=convert(varchar(20),t1.basetype) and r.base_docentry=t1.baseentry and r.base_linenum2=t1.baseline)),0) as reservation,oitm.invntryuom
		 from pdn1 t1  
		inner join opdn on opdn.docentry=t1.docentry
		inner join oitm on oitm.itemcode=t1.itemcode and oitm.manbtchnum='N'  and oitm.mansernum='N'
		inner join oitw on oitw.itemcode=t1.itemcode and oitw.whscode=t1.whscode
		where t1.docentry=@list_of_cols_val_tab_del and isnull(opdn.u_beas_version,'')=''
	open beas_delivery
	fetch next from beas_delivery into @beas_line,@beas_quantity,@beas_onhand,@beas_reserved,@beas_unit
	while @@FETCH_STATUS = 0
	  begin
	  if (@beas_quantity > @beas_onhand + @beas_quantity - @beas_reserved ) and @beas_reserved > 0 begin
		  --The variable @beas_onHand has the new value of stock (Stock - quantity of the document)
		  set @beas_txt=@beas_txt +isnull(@beas_line,'')+' Free:'+convert(varchar(20),convert(decimal(19,2), @beas_onhand - @beas_reserved))+' '+isnull(@beas_unit,'') +',  '
		  select @error = 500000
		  end
	  
		  fetch next from beas_delivery into @beas_line,@beas_quantity,@beas_onhand,@beas_reserved,@beas_unit
	  end 
	close beas_delivery
	deallocate beas_delivery
	if @error = 500000 begin
      select @error_message='Reserved goods can not be charged: '+@beas_txt
    end
  end 
 

   -- ------------ AP Invoice -------------------
   --We have to check this type of document because user can create Negative documents--
if (@object_type = '18') begin 
  -- Check negativ Stock on Bin-Warehouse
  select @ll_count= COUNT(*) from pch1   inner join oitw on oitw.itemcode = pch1.itemcode and oitw.whscode=pch1.whscode  
		inner join beas_whs on beas_whs.whscode=pch1.whscode and beas_whs.bintyp=1 where oitw.onhand < 0 and DocEntry=@list_of_cols_val_tab_del
  if @ll_count > 0
  begin
		  set @error_message='negative stock on a Bin-Warehouse is not allowed'
		  select @error = 500011
 end
 -- Check Reservation
  declare beas_delivery cursor for 
		select t1.itemcode+' Whs '+t1.whscode+' '+obtn.distnumber,itl1.quantity,obtq.quantity,
		isnull((select sum(r.quantity) from beas_reservation_line r where r.itemcode=t1.itemcode and r.whscode=t1.whscode and r.batchnum=obtn.distnumber and r.reservationtype='S' 
		and not(r.reservationtype='S' and r.base_type=convert(varchar(20),t1.basetype) and r.base_docentry=t1.baseentry and r.base_linenum2=t1.baseline)),0) as reservation,oitm.invntryuom
		 from pch1 t1  
		 inner join opch on opch.docentry=t1.docentry
		inner join oitm on oitm.itemcode=t1.itemcode and oitm.manbtchnum='Y' 
		inner join oitl on oitl.doctype=t1.objtype and oitl.docentry=t1.docentry and oitl.docline=t1.linenum
		inner join itl1 on itl1.logentry=oitl.logentry
		inner join obtq on obtq.itemcode=itl1.itemcode and obtq.sysnumber=itl1.sysnumber and obtq.whscode=t1.whscode
		inner join obtn on obtn.itemcode=itl1.itemcode and obtn.sysnumber=itl1.sysnumber
		where t1.docentry=@list_of_cols_val_tab_del and  isnull(opch.u_beas_version,'')=''
		union all
		select t1.itemcode+' '+t1.whscode+' '+osrn.distnumber+' ('+convert(varchar(20),osrn.sysnumber)+')',itl1.quantity,osrq.quantity,
		isnull((select sum(r.quantity) from beas_reservation_line r where r.itemcode=t1.itemcode and r.whscode=t1.whscode and r.batchnum=convert(varchar(20),osrn.sysnumber) and r.reservationtype='S' 
		and not(r.reservationtype='S' and r.base_type=convert(varchar(20),t1.basetype) and r.base_docentry=t1.baseentry and r.base_linenum2=t1.baseline)),0) as reservation,oitm.invntryuom
		 from pch1 t1  
		 inner join opch on opch.docentry=t1.docentry
		inner join oitm on oitm.itemcode=t1.itemcode and oitm.ManSerNum='Y' 
		inner join oitl on oitl.doctype=t1.objtype and oitl.docentry=t1.docentry and oitl.docline=t1.linenum
		inner join itl1 on itl1.logentry=oitl.logentry
		inner join osrq on osrq.itemcode=itl1.itemcode and osrq.sysnumber=itl1.sysnumber and osrq.whscode=t1.whscode
		inner join osrn on osrn.itemcode=itl1.itemcode and osrn.sysnumber=itl1.sysnumber
		where t1.docentry=@list_of_cols_val_tab_del and  isnull(opch.u_beas_version,'')=''
		union all
		select t1.itemcode+' Whs '+t1.whscode,t1.quantity,oitw.onhand,
		isnull((select sum(r.quantity) from beas_reservation_line r where r.itemcode=t1.itemcode and r.whscode=t1.whscode and (r.batchnum is null or r.batchnum='') and r.reservationtype='S' 
		and not(r.reservationtype='S' and r.base_type=convert(varchar(20),t1.basetype) and r.base_docentry=t1.baseentry and r.base_linenum2=t1.baseline)),0) as reservation,oitm.invntryuom
		 from pch1 t1  
		inner join opch on opch.docentry=t1.docentry
		inner join oitm on oitm.itemcode=t1.itemcode and oitm.manbtchnum='N'  and oitm.mansernum='N'
		inner join oitw on oitw.itemcode=t1.itemcode and oitw.whscode=t1.whscode
		where t1.docentry=@list_of_cols_val_tab_del and isnull(opch.u_beas_version,'')=''
	open beas_delivery
	fetch next from beas_delivery into @beas_line,@beas_quantity,@beas_onhand,@beas_reserved,@beas_unit
	while @@FETCH_STATUS = 0
	  begin
	  if (@beas_quantity > @beas_onhand + @beas_quantity - @beas_reserved ) and @beas_reserved > 0 begin
		  --The variable @beas_onHand has the new value of stock (Stock - quantity of the document)
		  set @beas_txt=@beas_txt +isnull(@beas_line,'')+' Free:'+convert(varchar(20),convert(decimal(19,2), @beas_onhand - @beas_reserved))+' '+isnull(@beas_unit,'') +',  '
		  select @error = 500000
		  end
	  
		  fetch next from beas_delivery into @beas_line,@beas_quantity,@beas_onhand,@beas_reserved,@beas_unit
	  end 
	close beas_delivery
	deallocate beas_delivery
	if @error = 500000 begin
      select @error_message='Reserved goods can not be charged: '+@beas_txt
    end
  end 

   -- ------------ Goods Return -------------------
if (@object_type = '21') begin 
  -- Check negativ Stock on Bin-Warehouse
  select @ll_count= COUNT(*) from rpd1   inner join oitw on oitw.itemcode = rpd1.itemcode and oitw.whscode=rpd1.whscode  
		inner join beas_whs on beas_whs.whscode=rpd1.whscode and beas_whs.bintyp=1 where oitw.onhand < 0 and DocEntry=@list_of_cols_val_tab_del
  if @ll_count > 0
  begin
		  set @error_message='negative stock on a Bin-Warehouse is not allowed'
		  select @error = 500011
 end
 -- Check Reservation
  declare beas_delivery cursor for 
		select t1.itemcode+' Whs '+t1.whscode+' '+obtn.distnumber,itl1.quantity,obtq.quantity,
		isnull((select sum(r.quantity) from beas_reservation_line r where r.itemcode=t1.itemcode and r.whscode=t1.whscode and r.batchnum=obtn.distnumber and r.reservationtype='S' 
		and not(r.reservationtype='S' and r.base_type=convert(varchar(20),t1.basetype) and r.base_docentry=t1.baseentry and r.base_linenum2=t1.baseline)),0) as reservation,oitm.invntryuom
		 from rpd1 t1  
		 inner join orpd on orpd.docentry=t1.docentry
		inner join oitm on oitm.itemcode=t1.itemcode and oitm.manbtchnum='Y' 
		inner join oitl on oitl.doctype=t1.objtype and oitl.docentry=t1.docentry and oitl.docline=t1.linenum
		inner join itl1 on itl1.logentry=oitl.logentry
		inner join obtq on obtq.itemcode=itl1.itemcode and obtq.sysnumber=itl1.sysnumber and obtq.whscode=t1.whscode
		inner join obtn on obtn.itemcode=itl1.itemcode and obtn.sysnumber=itl1.sysnumber
		where t1.docentry=@list_of_cols_val_tab_del and  isnull(orpd.u_beas_version,'')=''
		union all
		select t1.itemcode+' '+t1.whscode+' '+osrn.distnumber+' ('+convert(varchar(20),osrn.sysnumber)+')',itl1.quantity,osrq.quantity,
		isnull((select sum(r.quantity) from beas_reservation_line r where r.itemcode=t1.itemcode and r.whscode=t1.whscode and r.batchnum=convert(varchar(20),osrn.sysnumber) and r.reservationtype='S' 
		and not(r.reservationtype='S' and r.base_type=convert(varchar(20),t1.basetype) and r.base_docentry=t1.baseentry and r.base_linenum2=t1.baseline)),0) as reservation,oitm.invntryuom
		 from rpd1 t1  
		 inner join orpd on orpd.docentry=t1.docentry
		inner join oitm on oitm.itemcode=t1.itemcode and oitm.ManSerNum='Y' 
		inner join oitl on oitl.doctype=t1.objtype and oitl.docentry=t1.docentry and oitl.docline=t1.linenum
		inner join itl1 on itl1.logentry=oitl.logentry
		inner join osrq on osrq.itemcode=itl1.itemcode and osrq.sysnumber=itl1.sysnumber and osrq.whscode=t1.whscode
		inner join osrn on osrn.itemcode=itl1.itemcode and osrn.sysnumber=itl1.sysnumber
		where t1.docentry=@list_of_cols_val_tab_del and  isnull(orpd.u_beas_version,'')=''
		union all
		select t1.itemcode+' Whs '+t1.whscode,t1.quantity,oitw.onhand,
		isnull((select sum(r.quantity) from beas_reservation_line r where r.itemcode=t1.itemcode and r.whscode=t1.whscode and (r.batchnum is null or r.batchnum='') and r.reservationtype='S' 
		and not(r.reservationtype='S' and r.base_type=convert(varchar(20),t1.basetype) and r.base_docentry=t1.baseentry and r.base_linenum2=t1.baseline)),0) as reservation,oitm.invntryuom
		 from rpd1 t1  
		inner join orpd on orpd.docentry=t1.docentry
		inner join oitm on oitm.itemcode=t1.itemcode and oitm.manbtchnum='N'  and oitm.mansernum='N'
		inner join oitw on oitw.itemcode=t1.itemcode and oitw.whscode=t1.whscode
		where t1.docentry=@list_of_cols_val_tab_del and isnull(orpd.u_beas_version,'')=''
	open beas_delivery
	fetch next from beas_delivery into @beas_line,@beas_quantity,@beas_onhand,@beas_reserved,@beas_unit
	while @@FETCH_STATUS = 0
	  begin
	  if (@beas_quantity > @beas_onhand + @beas_quantity - @beas_reserved ) and @beas_reserved > 0 begin
		  --The variable @beas_onHand has the new value of stock (Stock - quantity of the document)
		  set @beas_txt=@beas_txt +isnull(@beas_line,'')+' Free:'+convert(varchar(20),convert(decimal(19,2), @beas_onhand - @beas_reserved))+' '+isnull(@beas_unit,'') +',  '
		  select @error = 500000
		  end
	  
		  fetch next from beas_delivery into @beas_line,@beas_quantity,@beas_onhand,@beas_reserved,@beas_unit
	  end 
	close beas_delivery
	deallocate beas_delivery
	if @error = 500000 begin
      select @error_message='Reserved goods can not be charged: '+@beas_txt
    end
  end 


   -- ------------ AP Cedit Note -------------------
if (@object_type = '19') begin 
  -- Check negativ Stock on Bin-Warehouse
  select @ll_count= COUNT(*) from rpc1   inner join oitw on oitw.itemcode = rpc1.itemcode and oitw.whscode=rpc1.whscode  
		inner join beas_whs on beas_whs.whscode=rpc1.whscode and beas_whs.bintyp=1 where oitw.onhand < 0 and DocEntry=@list_of_cols_val_tab_del
  if @ll_count > 0
  begin
		  set @error_message='negative stock on a Bin-Warehouse is not allowed'
		  select @error = 500011
 end
 -- Check Reservation
  declare beas_delivery cursor for 
		select t1.itemcode+' Whs '+t1.whscode+' '+obtn.distnumber,itl1.quantity,obtq.quantity,
		isnull((select sum(r.quantity) from beas_reservation_line r where r.itemcode=t1.itemcode and r.whscode=t1.whscode and r.batchnum=obtn.distnumber and r.reservationtype='S' 
		and not(r.reservationtype='S' and r.base_type=convert(varchar(20),t1.basetype) and r.base_docentry=t1.baseentry and r.base_linenum2=t1.baseline)),0) as reservation,oitm.invntryuom
		 from rpc1 t1  
		 inner join orpc on orpc.docentry=t1.docentry
		inner join oitm on oitm.itemcode=t1.itemcode and oitm.manbtchnum='Y' 
		inner join oitl on oitl.doctype=t1.objtype and oitl.docentry=t1.docentry and oitl.docline=t1.linenum
		inner join itl1 on itl1.logentry=oitl.logentry
		inner join obtq on obtq.itemcode=itl1.itemcode and obtq.sysnumber=itl1.sysnumber and obtq.whscode=t1.whscode
		inner join obtn on obtn.itemcode=itl1.itemcode and obtn.sysnumber=itl1.sysnumber
		where t1.docentry=@list_of_cols_val_tab_del and  isnull(orpc.u_beas_version,'')=''
		union all
		select t1.itemcode+' '+t1.whscode+' '+osrn.distnumber+' ('+convert(varchar(20),osrn.sysnumber)+')',itl1.quantity,osrq.quantity,
		isnull((select sum(r.quantity) from beas_reservation_line r where r.itemcode=t1.itemcode and r.whscode=t1.whscode and r.batchnum=convert(varchar(20),osrn.sysnumber) and r.reservationtype='S' 
		and not(r.reservationtype='S' and r.base_type=convert(varchar(20),t1.basetype) and r.base_docentry=t1.baseentry and r.base_linenum2=t1.baseline)),0) as reservation,oitm.invntryuom
		 from rpc1 t1  
		 inner join orpc on orpc.docentry=t1.docentry
		inner join oitm on oitm.itemcode=t1.itemcode and oitm.ManSerNum='Y' 
		inner join oitl on oitl.doctype=t1.objtype and oitl.docentry=t1.docentry and oitl.docline=t1.linenum
		inner join itl1 on itl1.logentry=oitl.logentry
		inner join osrq on osrq.itemcode=itl1.itemcode and osrq.sysnumber=itl1.sysnumber and osrq.whscode=t1.whscode
		inner join osrn on osrn.itemcode=itl1.itemcode and osrn.sysnumber=itl1.sysnumber
		where t1.docentry=@list_of_cols_val_tab_del and  isnull(orpc.u_beas_version,'')=''
		union all
		select t1.itemcode+' Whs '+t1.whscode,t1.quantity,oitw.onhand,
		isnull((select sum(r.quantity) from beas_reservation_line r where r.itemcode=t1.itemcode and r.whscode=t1.whscode and (r.batchnum is null or r.batchnum='') and r.reservationtype='S' 
		and not(r.reservationtype='S' and r.base_type=convert(varchar(20),t1.basetype) and r.base_docentry=t1.baseentry and r.base_linenum2=t1.baseline)),0) as reservation,oitm.invntryuom
		 from rpc1 t1  
		inner join orpc on orpc.docentry=t1.docentry
		inner join oitm on oitm.itemcode=t1.itemcode and oitm.manbtchnum='N'  and oitm.mansernum='N'
		inner join oitw on oitw.itemcode=t1.itemcode and oitw.whscode=t1.whscode
		where t1.docentry=@list_of_cols_val_tab_del and isnull(orpc.u_beas_version,'')=''
	open beas_delivery
	fetch next from beas_delivery into @beas_line,@beas_quantity,@beas_onhand,@beas_reserved,@beas_unit
	while @@FETCH_STATUS = 0
	  begin
	  if (@beas_quantity > @beas_onhand + @beas_quantity - @beas_reserved ) and @beas_reserved > 0 begin
		  --The variable @beas_onHand has the new value of stock (Stock - quantity of the document)
		  set @beas_txt=@beas_txt +isnull(@beas_line,'')+' Free:'+convert(varchar(20),convert(decimal(19,2), @beas_onhand - @beas_reserved))+' '+isnull(@beas_unit,'') +',  '
		  select @error = 500000
		  end
	  
		  fetch next from beas_delivery into @beas_line,@beas_quantity,@beas_onhand,@beas_reserved,@beas_unit
	  end 
	close beas_delivery
	deallocate beas_delivery
	if @error = 500000 begin
      select @error_message='Reserved goods can not be charged: '+@beas_txt
    end
  end 


  -- ------------ Issue -------------------
if (@object_type = '60') begin 
  -- Check negativ Stock on Bin-Warehouse
  select @ll_count= COUNT(*) from IGe1   inner join oitw on oitw.itemcode = ige1.itemcode and oitw.whscode=ige1.whscode  
		inner join beas_whs on beas_whs.whscode=ige1.whscode and beas_whs.bintyp=1 where oitw.onhand < 0 and DocEntry=@list_of_cols_val_tab_del
  if @ll_count > 0
  begin
		  set @error_message='negative stock on a Bin-Warehouse is not allowed'
		  select @error = 500011
 end
  
  -- Reservation
  declare beas_issue cursor for 
		select t1.itemcode+' Whs '+t1.whscode+' '+obtn.distnumber,abs(itl1.quantity),obtq.quantity,
		isnull((select sum(r.quantity) from beas_reservation_line r where r.reservationtype='S' and r.itemcode=t1.itemcode and r.whscode=t1.whscode and r.batchnum=obtn.distnumber  ),0) as reservation,oitm.invntryuom
		 from ige1 t1  
		 inner join oige on oige.docentry=t1.docentry
		inner join oitm on oitm.itemcode=t1.itemcode and oitm.manbtchnum='Y' 
		inner join oitl on oitl.doctype=t1.objtype and oitl.docentry=t1.docentry and oitl.docline=t1.linenum
		inner join itl1 on itl1.logentry=oitl.logentry
		inner join obtq on obtq.itemcode=itl1.itemcode and obtq.sysnumber=itl1.sysnumber and obtq.whscode=t1.whscode
		inner join obtn on obtn.itemcode=itl1.itemcode and obtn.sysnumber=itl1.sysnumber
		where t1.docentry=@list_of_cols_val_tab_del and isnull(oige.u_beas_version,'')=''
		union all
		select t1.itemcode+' '+t1.whscode+' '+osrn.distnumber+' ('+convert(varchar(20),osrn.sysnumber)+')',itl1.quantity,osrq.quantity,
		isnull((select sum(r.quantity) from beas_reservation_line r where r.reservationtype='S' and r.itemcode=t1.itemcode and r.whscode=t1.whscode and r.batchnum=convert(varchar(20),osrn.sysnumber)),0) as reservation,oitm.invntryuom
		 from ige1 t1  
		 inner join oige on oige.docentry=t1.docentry
		inner join oitm on oitm.itemcode=t1.itemcode and oitm.ManSerNum='Y' 
		inner join oitl on oitl.doctype=t1.objtype and oitl.docentry=t1.docentry and oitl.docline=t1.linenum
		inner join itl1 on itl1.logentry=oitl.logentry
		inner join osrq on osrq.itemcode=itl1.itemcode and osrq.sysnumber=itl1.sysnumber and osrq.whscode=t1.whscode
		inner join osrn on osrn.itemcode=itl1.itemcode and osrn.sysnumber=itl1.sysnumber
		where t1.docentry=@list_of_cols_val_tab_del and isnull(oige.u_beas_version,'')=''
		union all
		select t1.itemcode+' Whs '+t1.whscode,t1.quantity,oitw.onhand,
		isnull((select sum(r.quantity) from beas_reservation_line r where r.reservationtype='S' and r.itemcode=t1.itemcode and r.whscode=t1.whscode and (r.batchnum is null or r.batchnum='')),0) as reservation,oitm.invntryuom
		 from ige1 t1  
		 inner join oige on oige.docentry=t1.docentry
		inner join oitm on oitm.itemcode=t1.itemcode and oitm.manbtchnum='N'  and oitm.mansernum='N'
		inner join oitw on oitw.itemcode=t1.itemcode and oitw.whscode=t1.whscode
		where t1.docentry=@list_of_cols_val_tab_del and isnull(oige.u_beas_version,'')=''
	open beas_issue
	fetch next from beas_issue into @beas_line,@beas_quantity,@beas_onhand,@beas_reserved,@beas_unit
	while @@FETCH_STATUS = 0
	  begin
	  if (@beas_quantity > @beas_onhand + @beas_quantity - @beas_reserved ) and @beas_reserved > 0 begin
		  --The variable @beas_onHand has the new value of stock (Stock - quantity of the document)
		  set @beas_txt=@beas_txt +isnull(@beas_line,'')+' Free:'+convert(varchar(20),convert(decimal(19,2),@beas_onhand - @beas_reserved))+' '+isnull(@beas_unit,'') +',  '
		  select @error = 500001
		  end
	  
	  fetch next from beas_issue into @beas_line,@beas_quantity,@beas_onhand,@beas_reserved,@beas_unit
	  end 
	close beas_issue
	deallocate beas_issue
	if @error = 500001 begin
      select @error_message='Reserved goods can not be charged: '+@beas_txt
    end
  end 

    -- ------------ Transfer -------------------
if (@object_type = '67') begin 
	  -- Check negativ Stock on Bin-Warehouse
	  select @ll_count= COUNT(*) from wtr1 inner join owtr on owtr.docentry=wtr1.docentry   inner join oitw on oitw.itemcode = wtr1.itemcode and oitw.whscode=owtr.filler  
			inner join beas_whs on beas_whs.whscode=owtr.filler and beas_whs.bintyp=1 where oitw.onhand < 0 and wtr1.DocEntry=@list_of_cols_val_tab_del
	  if @ll_count > 0
	  begin
			  set @error_message='negative stock on a Bin-Warehouse is not allowed'
			  select @error = 500011
	 end
	 -- Check Reservation -- 11.6.12 M.Heigl: use owtr and not oibt
    declare beas_transfer cursor for 
		select t1.itemcode+' Whs '+owtr.filler+' '+obtn.distnumber,abs(itl1.quantity),obtq.quantity,
		isnull((select sum(r.quantity) from beas_reservation_line r where r.reservationtype='S' and r.itemcode=t1.itemcode and r.whscode=owtr.filler and r.batchnum=obtn.distnumber  ),0) as reservation,oitm.invntryuom
		 from wtr1 t1  
		 inner join owtr on owtr.docentry=t1.docentry
		inner join oitm on oitm.itemcode=t1.itemcode and oitm.manbtchnum='Y' 
		inner join oitl on oitl.doctype=t1.objtype and oitl.docentry=t1.docentry and oitl.docline=t1.linenum
		inner join itl1 on itl1.logentry=oitl.logentry
		inner join obtq on obtq.itemcode=itl1.itemcode and obtq.sysnumber=itl1.sysnumber and obtq.whscode=owtr.filler
		inner join obtn on obtn.itemcode=itl1.itemcode and obtn.sysnumber=itl1.sysnumber
		where t1.docentry=@list_of_cols_val_tab_del and isnull(owtr.u_beas_version,'')=''
		and itl1.quantity > 0 -- Only get positive rows, all transfer generates 2 rows (one positive and other negative)
		union all
		select t1.itemcode+' '+owtr.filler+' '+osrn.distnumber+' ('+convert(varchar(20),osrn.sysnumber)+')',itl1.quantity,osrq.quantity,
		isnull((select sum(r.quantity) from beas_reservation_line r where r.reservationtype='S' and r.itemcode=t1.itemcode and r.whscode=owtr.filler and r.batchnum=convert(varchar(20),osrn.sysnumber)),0) as reservation,oitm.invntryuom
		 from wtr1 t1  
		 inner join owtr on owtr.docentry=t1.docentry
		inner join oitm on oitm.itemcode=t1.itemcode and oitm.ManSerNum='Y' 
		inner join oitl on oitl.doctype=t1.objtype and oitl.docentry=t1.docentry and oitl.docline=t1.linenum
		inner join itl1 on itl1.logentry=oitl.logentry
		inner join osrq on osrq.itemcode=itl1.itemcode and osrq.sysnumber=itl1.sysnumber and osrq.whscode=owtr.filler
		inner join osrn on osrn.itemcode=itl1.itemcode and osrn.sysnumber=itl1.sysnumber
		where t1.docentry=@list_of_cols_val_tab_del and isnull(owtr.u_beas_version,'')=''
		and itl1.quantity > 0 -- Only get positive rows, all transfer generates 2 rows (one positive and other negative)
		union all
		select t1.itemcode+' Whs '+owtr.filler,t1.quantity,oitw.onhand,
		isnull((select sum(r.quantity) from beas_reservation_line r where r.reservationtype='S' and r.itemcode=t1.itemcode and r.whscode=owtr.filler and (r.batchnum is null or r.batchnum='')),0) as reservation,oitm.invntryuom
		 from wtr1 t1  
		 inner join owtr on owtr.docentry=t1.docentry
		inner join oitm on oitm.itemcode=t1.itemcode and oitm.manbtchnum='N'  and oitm.mansernum='N'
		inner join oitw on oitw.itemcode=t1.itemcode and oitw.whscode=owtr.filler
		where t1.docentry=@list_of_cols_val_tab_del and isnull(owtr.u_beas_version,'')=''
		and t1.quantity > 0 -- Only get positive rows, all transfer generates 2 rows (one positive and other negative)
	open beas_transfer
	fetch next from beas_transfer into @beas_line,@beas_quantity,@beas_onhand,@beas_reserved,@beas_unit
	while @@FETCH_STATUS = 0
	  begin
	  if (@beas_quantity > @beas_onhand + @beas_quantity - @beas_reserved ) and @beas_reserved > 0 begin
		  --The variable @beas_onHand has the new value of stock (Stock - quantity of the document)
		  set @beas_txt=@beas_txt +isnull(@beas_line,'')+' Free:'+convert(varchar(20),convert(decimal(19,2),@beas_onhand - @beas_reserved))+' '+isnull(@beas_unit,'') +',  '
		  select @error = 500002
		  end
	  
	  fetch next from beas_transfer into @beas_line,@beas_quantity,@beas_onhand,@beas_reserved,@beas_unit
	  end 
	close beas_transfer
	deallocate beas_transfer
	if @error = 500002 begin
      select @error_message='Reserved goods can not be charged: '+@beas_txt      
    end
  end   

-- /beasarea End
--------------------------------------------------------------------------------------------------------------------------------













/*FI:modifycation by 2014.03.12*/
/*------------------------------------------------------- Validation - FI  ----------------------------------------------------*/
		DECLARE @BPGroup NVARCHAR(10)
		DECLARE @BPType NVARCHAR(20)
	    DECLARE @PayAccount NVARCHAR(20)
	    DECLARE @DownPayAccount  NVARCHAR(20)
        DECLARE @TaxCode  NVARCHAR(20)
    
        DECLARE @FAGroup NVARCHAR(20) 
		DECLARE @MainFANo NVARCHAR(20) 
		DECLARE @ItemCode NVARCHAR(20) 
		DECLARE @ItemGroup NVARCHAR(20) 
		DECLARE @FAStatus NVARCHAR(2) 		 
		DECLARE @ItemType  NVARCHAR(20) 
		DECLARE @InvntItem NVARCHAR(2) 
		DECLARE @SellItem NVARCHAR(2)  
		DECLARE @PrchseItem  NVARCHAR(2)  
		DECLARE @AssetClass NVARCHAR(20)
        DECLARE @ValidFROM  DATETIME
        DECLARE @ValidTo  DATETIME
        DECLARE @CapitalProjectID NVARCHAR(20)
        DECLARE @Location NVARCHAR(20)
        DECLARE @MaxCode INT
        
		DECLARE @TrdPrtRel NVARCHAR(10)
		DECLARE @TrdPrtID NVARCHAR(20)
		DECLARE @TrdPrtID_JE NVARCHAR(20)      
		DECLARE @FunctionArea NVARCHAR(20)
		DECLARE @FunctionArea_JE NVARCHAR(20)
		DECLARE @ONlyAutoTrans NVARCHAR(20)
		DECLARE @LocManTran NVARCHAR(20)
		DECLARE @Account NVARCHAR(15)
	    DECLARE @TransType NVARCHAR(15)
	    DECLARE @CostCenterRelvnt NVARCHAR(15)	    
	    DECLARE @CostCenter NVARCHAR(15)	
	    DECLARE @HFMAccount NVARCHAR(20)  
	    DECLARE @PrjRelvnt NVARCHAR(20)  	    
	    DECLARE @Project NVARCHAR(20)  	 
		DECLARE @PrintJENo NVARCHAR(20)  	  
		DECLARE @ExternalJENo NVARCHAR(20) 
		DECLARE @TransCode NVARCHAR(20) 
		DECLARE @CashFlowRelvnt NVARCHAR(2)
		DECLARE @CashFlowItem NVARCHAR(20)
		DECLARE @StornoToTr NVARCHAR(20)
		DECLARE @AuotStorno NVARCHAR(2)
		DECLARE @Remark NVARCHAR(2000)
		
		DECLARE @DebCred NVARCHAR(5)
		DECLARE @JETotalLC NUMERIC(19,4)
		DECLARE @JETotalSC NUMERIC(19,4) 
			       
	    DECLARE @LineID NVARCHAR(15)
	    DECLARE @Count NVARCHAR(15)

		DECLARE @AcctType NVARCHAR(20) 
		DECLARE @DocDate DateTime
	    DECLARE @DocType NVARCHAR(20)  
		DECLARE @InvType NVARCHAR(20)
	    DECLARE @PaymentMethod NVARCHAR(20)  
	    DECLARE @DocCur NVARCHAR(20) 
	    DECLARE @BaseProject NVARCHAR(20) 	     
	    DECLARE @BaseCostCenter NVARCHAR(20) 	    
	    DECLARE @BaseDocType NVARCHAR(20)
		DECLARE @BaseDocNo NVARCHAR(20)
		DECLARE @BaseLine NVARCHAR(20)			
	    DECLARE @orignInvNo NVARCHAR(20)		
	    DECLARE @orignLineNo NVARCHAR(20)				    			
	    DECLARE @PaymentTerm NVARCHAR(20)
	    DECLARE @VendorRefNo NVARCHAR(20)  
	    DECLARE @PaymentMethodCur NVARCHAR(20) 
	    DECLARE @PayBlock NVARCHAR(20) 
	    DECLARE @PayBlockRef NVARCHAR(20) 
		DECLARE @ReleasePayment NVARCHAR(2) 
	    DECLARE @Canceled NVARCHAR(2) 
		
	    DECLARE @OrignValue NVARCHAR(20)
	    
		DECLARE @GRlinetotal NUMERIC(19,4)
		DECLARE @GRtnlinetotal NUMERIC(19,4)
		DECLARE @PINVlinetotal NUMERIC(19,4)
	    DECLARE @CGRlinetotal NUMERIC(19,4)
		DECLARE @CINVlinetotal NUMERIC(19,4)
		DECLARE @CGRtnlinetotal NUMERIC(19,4)
		DECLARE @CCMlinetotal NUMERIC(19,4)
		DECLARE @PCMlinetotal NUMERIC (19,4)

		DECLARE @IsActiv NVARCHAR(4)
		DECLARE @tolValue NUMERIC (19,4)
		DECLARE @tolRate  NUMERIC (19,4)
		DECLARE @linetotal NUMERIC (19,4)
-----------------------------------------------------------------------------------------------------------------------------------------

/**********************
   Chart of Accounts
**********************/
IF( @object_type='1') 
BEGIN 
	IF( @transaction_type IN ('U','A'))   
	BEGIN

		SELECT 
		@CostCenter=T0.Dim1Relvnt, 
		@Account=T0.AcctCode,
		@HFMAccount=T0.AccntntCod,
		@TrdPrtRel=T0.U_TrdPrtRel,
		@TrdPrtID=T0.U_TrdPrtID,
		@LocManTran=T0.LocManTran,
		@FunctionArea=T0.U_FunctionArea 
		FROM OACT T0 
		WHERE T0.AcctCode=@list_of_cols_val_tab_del
		-------------------------------------------------------------------
		/*
		   Coding ID:COA_01
		   By:Jack
		   Date:20131111
		   description: 1.If account code is 1~6XXXXXXXXX series, then the field ‘HFM Account’ cannot be null.
						2.If account code is Greater than 7XXXXXXXXX series, then the field ‘HFM Account’ must be null.
		   Remark:HFM Account validation
		*/
		-------------------------------------------------------------------		
		IF LEFT(@Account,1) IN ('1','2','3','4','5','6') 
		BEGIN
		    IF (ISNULL(@HFMAccount,'') ='')
		    BEGIN
				SET @error=1
				SET @error_message='(COA_01)Please input HFM Account!'
			END
		END
		
		IF LEFT(@Account,1)>='7' 
		BEGIN
		    IF (ISNULL(@HFMAccount,'')<>'')
		    BEGIN
				SET @error=1
				SET @error_message='(COA_02)Cannot input HFM Account for GL Account which is greater than 7000000000!'
			END
		END	
		-------------------------------------------------------------------
		/*
		   Coding ID:COA_02
		   By:Jack
		   Date:20131111
		   description: 1.If account was specified a trading partner id, but the Trading partner id not existing in trading partner table, then this account cannot be stored into system. 
						2.If trading partner relative set as “N”, trading partner ID can’t fill the information
		   Remark:Trading Partner ID Validation
		*/
		-------------------------------------------------------------------				
		IF @TrdPrtRel='N'
		BEGIN
		    IF  (ISNULL( @TrdPrtID,'')<>'')
		    BEGIN
				SET @error=1
				SET @error_message='(COA_02_01)Cannot input Trading Partner ID for non trading partner relative account!'
			END
		END	
		
		IF (ISNULL( @TrdPrtID,'')<>'')
		BEGIN
		    IF(SELECT COUNT(*) FROM [@ZFTBD] T1 WHERE @TrdPrtID=T1.Code )<1
		    BEGIN
				SET @error=1
				SET @error_message='(COA_02_02)Please input a valid Trading Partner ID for this account!'
			END
		END 
		-------------------------------------------------------------------
		/*
		   Coding ID:COA_03
		   By:Jack
		   Date:20131111
		   description: 1.If account code is 1-3XXXXXXXXX series, then the field ‘Function Area’ must be null.
						2.If account code is 4~6XXXXXXXXX series, then the field ‘Function Area’ cannot be null.
						3.If account code is gerater than 7XXXXXXXXX series and controlled by cost center, then ‘function area’ must be null.
						4.If account code is greater than 7XXXXXXXXX series and not controlled by cost center, then ‘function area can’t be null
						5.If account was specified a function area, but the function area does not exists in function area table, then this account cannot be stored into system. 
		   Remark:Function Area Validation
		*/
		-------------------------------------------------------------------					
		IF (LEFT(@Account,1) IN ('1','2','3') )
		BEGIN
			IF ( ISNULL(@FunctionArea,'')<>'' )
			BEGIN
				SET @error=1
				SET @error_message='(COA_03_01)Cannot assign Function Area for 1-3 series account !'
			END	
		END
		
		IF (LEFT(@Account,1) IN ('4','5','6') )
		BEGIN
			IF ( ISNULL(@FunctionArea,'') ='' )
			BEGIN
				SET @error=1
				SET @error_message='(COA_03_02)Please assign Function Area for 4-6 series account !'
			END	
		END
		
		IF (LEFT(@Account,1)>='7')  AND ( @CostCenter='Y' )
		BEGIN
			IF ( ISNULL(@FunctionArea,'')<>'' )
			BEGIN
				SET @error=1
				SET @error_message='(COA_03_03)Cannot assign Function Area for cost center controled 7+ series account!'
			END
		END	
			
		IF (LEFT(@Account,1) >='7' ) AND ( @CostCenter='N' )
		BEGIN
			IF ( ISNULL(@FunctionArea,'') ='' )
			BEGIN
				SET @error=1
				SET @error_message='(COA_03_04)Please assign Function Area for cost center controled  7+ series account !'
			END
		END	
				
		IF ( ISNULL(@FunctionArea,'')<>'' )
		BEGIN
		    IF(SELECT COUNT(*) FROM OCCT T1 WHERE @FunctionArea =T1.CctCode )<1
		    BEGIN
				SET @error=1
				SET @error_message='(COA_03_05)Please input a valid Function Area for this account !'
			END
		END 
	END
END

/**********************
  Business Partner Master Data
**********************/
IF( @object_type='2') 
BEGIN 
	IF( @transaction_type IN ('U','A'))   
	BEGIN
	SELECT  @TaxCode=T0.ECVatGroup,
			@DownPayAccount=T1.AcctCode,
			@PaymentMethod=T0.PymCode,
			@AcctType=T1.AcctType, 
			@PayAccount=T0.DebPayAcct,
			@BPGroup=T0.GroupCode, 
			@BPType=T0.CardType,
			@TrdPrtID=T0.U_TrdPrtID 
	FROM OCRD T0 
	     LEFT JOIN CRD3 T1 ON  T0.CardCode=T1.CardCode  
    WHERE T0.CardCode=@list_of_cols_val_tab_del 
		-------------------------------------------------------------------
		/*
		   Coding ID:BP_001
		   By:Jack
		   Date:20131111
		   description: User should assign input tax code to vendor master data, otherwise system doesn’t allow to save the vendor into the system.
		   Remark:Tax Code validation
		*/
		-------------------------------------------------------------------				
		IF @BPType='S' AND ISNULL(@TaxCode,'')=''
        BEGIN
			SET @error=1
			SET @error_message='(BP_001)Please entered taxcode for current Vendor!'
		END
		-------------------------------------------------------------------
		/*
		   Coding ID:BP_002
		   By:Jack
		   Date:20131111
		   description: User should select default payment method for Vendor, otherwise this vendor cannot be stored into system.
		   Remark:Set default Payment Method Validation
		*/
		-------------------------------------------------------------------				
		IF  @PaymentMethod='-1'
        BEGIN
			SET @error=1
			SET @error_message='(BP_002)Please activate at least one payment method and set as default for current BP'
		END
		-------------------------------------------------------------------
		/*
		   Coding ID:BP_003
		   By:Jack
		   Date:20131111
		   description: 1. When user assigns TP to BP (vendor or customer), system will validate the value against trading partner table.
						2. For non internal BP, trading partner ID can't fill any information.
						3. For internal BP, trading partner ID must be filled.
		   Remark:Trading Partner ID Validation
		*/
		-------------------------------------------------------------------	   
		IF (ISNULL( @TrdPrtID,'')<>'')
		BEGIN
			IF  @BPGroup IN ('104','103','102') --Extenal BP group
	        BEGIN
				SET @error=1
				SET @error_message='(BP_003_01)Cannot input a Trading Partner ID for non internal BP!'
			END
		END
		
		IF (ISNULL( @TrdPrtID,'')<>'')
		BEGIN
		    IF(SELECT COUNT(*) FROM [@ZFTBD] T1 WHERE @TrdPrtID=T1.Code )<1
		    BEGIN
				SET @error=1
				SET @error_message='(BP_003_02)Please input a valid Trading Partner ID for this account!'
			END
		END 

		IF (ISNULL( @TrdPrtID,'')='')
		BEGIN
			IF  @BPGroup IN ('110','101') --Internal BP group \*Vince,20140218,100->110*\
	        BEGIN
				SET @error=1
				SET @error_message='(BP_003_02)Please input a Trading Partner ID for internal BP!'
			END
		END
		-------------------------------------------------------------------
		/*
		   Coding ID:BP_004
		   By:Jack
		   Date:20131111
		   description: 1. For external vendor, set AP account as 2011020000 (Trade Accounts Payable),otherwise this vendor cannot be stored into system.
						2. For employee, set AP account as 2011050100 (other account payable - employee travel expense),otherwise this vendor cannot be stored into system.
						3. For internal vendor, set AP account as 2011020100 (Intercompany A/P),otherwise this vendor cannot be stored into system.
						4. For internal vendor, it doesn't allow inpuuting down payment account, otherwise this vendor can't save into system
						5. For external customer, set AR account as 1021010000 (Trade Accounts Receivable),otherwise this customer cannot be stored into system.
						6. For internal customer, set AP account as 1024010000 (InterCompany A/R),otherwise this customer cannot be stored into system.
						7. For internal customer, it doesn't allow inpuuting down payment account, otherwise this customercan't save into system
		   Remark:AP Account Validation
		*/
		-------------------------------------------------------------------	 
		IF @BPType='S'
		BEGIN
			IF @BPGroup IN ('103') AND @PayAccount <>'2011020000'
			BEGIN
				SET @error=1
				SET @error_message='(BP_004_01)Please set account 2011020000 as payable account for external Vendor! '		
			END 
			
			IF @BPGroup IN ('104') AND @PayAccount <>'2011050100'
			BEGIN
				SET @error=1
				SET @error_message='(BP_004_02)Please set account 2011050100 as payable account for employee Vendor! '
			END 
			
			IF @BPGroup IN ('101') AND @PayAccount <>'2054010000'
			BEGIN
				SET @error=1
				SET @error_message='(BP_004_03)Please set account 2054010000 as payable account for internal Vendor! '
            END
				
			IF @BPGroup IN ('101') AND @AcctType='D' AND ( ISNULL(@DownPayAccount,'')<>'')
			BEGIN
				SET @error=1
				SET @error_message='(BP_004_04)Cannot set Down Payment Payables account for internal Vendor!'
			END		
		END		
		---Customer AR Account validation
		IF @BPType='C'
		BEGIN
			IF @BPGroup IN ('102') AND @PayAccount <>'1021010000'
			BEGIN	
				SET @error=1
				SET @error_message='(BP_004_05)Please set account 1021010000 as receivable account for external customer! '
			END 
			
			IF @BPGroup IN ('110') AND @PayAccount <>'1024010000'  /*Vince,20140218,100->110*/
			BEGIN
				SET @error=1
				SET @error_message='(BP_004_06)Please set account 1024010000 as receivable account for internal customer! '
			END
				
			IF @BPGroup IN ('110') AND @AcctType='D' AND ( ISNULL(@DownPayAccount,'')<>'')  /*Vince,20140218,100->110*/
			BEGIN
				SET @error=1
				SET @error_message='(BP_004_07)Cannot set Down Payment Receivables account for internal customer '
			END
		END
	END
END

/**********************
   Asset Master Data
**********************/
IF( @object_type='4') 
BEGIN 
      
	IF( @transaction_type IN ('U','A'))   
	BEGIN

	SELECT  @CapitalProjectID=T1.AttriTxt2,
			@Location=T0.Location,
			@AssetClass=T0.AssetClass,
			@InvntItem=T0.InvntItem,
			@SellItem=T0.SellItem,
			@PrchseItem=T0.PrchseItem,
			@ItemType=T0.ItemType,
			@ItemGroup=t0.ItmsGrpCod,
			@ItemCode=T0.ItemCode,
			@MainFANo=T0.InventryNo,
			@FAGroup=T0.AssetGroup ,
			@FAStatus=t0.AsstStatus
	FROM OITM T0 
	     LEFT JOIN ITM13 T1 ON T0.ItemCode=T1.ItemCode 
	WHERE T0.ItemCode=@list_of_cols_val_tab_del 
 	    
	    --Fixed Asset Master Data Validation
	    IF @ItemType='F'
	    BEGIN 			
			-------------------------------------------------------------------
			/*
			   Coding ID:AMD_07
			   By:Jack
			   Date:20131111
			   description:If the project matrix is not null, then the fixed asset cannot be stored into system
			   Remark: Project Validation
			*/
			-------------------------------------------------------------------				    
		    --Cannot assign project to fixed Asset master data 
			IF (SELECT COUNT(*) FROM ITM5 T1 WHERE T1.ItemCode= @ItemCode)>=1
			BEGIN
	    		SET @error=1
				SET @error_message='(AMD_07)Cannot assign project to Fixed Asset Master Data !'
			END
			-------------------------------------------------------------------
			/*
			   Coding ID:AMD_08
			   By:Jack
			   Date:20131111
			   description:If the capital project ID of fixed asset is null, then the fixed asset cannot be stored into system
			   Remark: Capital project ID validation
			*/
			-------------------------------------------------------------------				    
		    --Capital Project ID is mandentory for fixed Asset master data 
			IF ISNULL(@CapitalProjectID,'')=''
			BEGIN
	    		SET @error=1
				SET @error_message='(AMD_08) Please assign an appropriate capital project id to Fixed Asset Master Data !'
			END

			-------------------------------------------------------------------
			/*
			   Coding ID:AMD_10
			   By:Jack
			   Date:20131111
			   description: 1. If the cost center field is null , then the fixed asset cannot be stored into system
							2. If there are more than one cost centers, the valid periods in cost center assignment must be continuous.
							3. The ValidTo Date of last cost center of fixed asset must be 9999.12.31 
			   Remark: Cost Center Validation
			*/
			-------------------------------------------------------------------			
		    --Cost Center
			IF ISNULL((SELECT TOP 1 YEAR(T1.ValidTo) FROM ITM6 T1 WHERE T1.ItemCode=@list_of_cols_val_tab_del ORDER BY LineNum DESC ),'')<>'9999'
			BEGIN 
				SET @error=1
				SET @error_message='(AMD_10_01) Please set 9999.12.31 as ValidTo Date for last one cost center !'		
			END
		    --Cost Center validation
			IF (SELECT COUNT(*) FROM  OITM T0 LEFT JOIN ITM6 T1 ON T0.ItemCode=T1.ItemCode WHERE  T0.ItemCode=@list_of_cols_val_tab_del )>1
			BEGIN
    			SELECT @Count=COUNT(*) FROM  OITM T0 LEFT JOIN ITM6 T1 ON T0.ItemCode=T1.ItemCode WHERE T0.ItemCode=@list_of_cols_val_tab_del
				SET @LineID=@Count
				WHILE @LineID >= (@Count-2)
				BEGIN
					SELECT  @ValidTo=T1.ValidTo FROM  OITM T0 LEFT JOIN ITM6 T1 ON T0.ItemCode=T1.ItemCode WHERE T0.ItemCode=@list_of_cols_val_tab_del AND T1.LineNum=@LineID-1
					IF ISNULL(@ValidTo,'')<>''
					BEGIN 
						SELECT  @ValidFROM=T1.ValidFROM FROM  OITM T0 LEFT JOIN ITM6 T1 ON T0.ItemCode=T1.ItemCode WHERE T0.ItemCode=@list_of_cols_val_tab_del AND T1.LineNum=@LineID
						IF DATEDIFF(DAY,@ValidTo,@ValidFROM)>1
						BEGIN
	    					SET @error=1
							SET @error_message='(AMD_10_02)IF there are more than one cost centers, the valid periods in cost center assignment must be continuous.!'			
						END
					END
				   SET @LineID=@LineID-1
				END				 
			 END 
			 		    --Cost Center is mandentory for fixed Asset master data 
			IF (SELECT COUNT(*) FROM ITM6 T1 WHERE T1.ItemCode= @ItemCode)=0
			BEGIN
	    		SET @error=1
				SET @error_message=' (AMD_10_03)Please assign an appropriate cost center to Fixed Asset Master Data !'
			END
			-------------------------------------------------------------------
			/*
			   Coding ID:AMD_09
			   By:Jack
			   Date:20131111
			   description: If the location of fixed asset is null, then the fixed asset cannot be stored into system
			   Remark: Fixed Asset Location validation
			*/
			-------------------------------------------------------------------					
			--Location is mandentory for fixed Asset master data 
			IF ISNULL(@Location,'')=''
			BEGIN
	    		SET @error=1
				SET @error_message='(AMD_09) Please assign an appropriate location to Fixed Asset Master Data !'
			END
			-------------------------------------------------------------------
			/*
			   Coding ID:AMD_05
			   By:Jack
			   Date:20131111
			   description: 1.If asset group is interest fixed asset, Cost center should be the same as main fixed asset.
							2.If asset group is interest fixed asset, Asset Class should be the same as main fixed asset.
			   Remark:Valid cost center/Asset Class should be the same as main fixed asset
			*/
			-------------------------------------------------------------------	
			--The Asset class of main fixed asset must is same with interest fixed Asset class
			IF @FAGroup='I' AND ISNULL(@MainFANo,'')<>'' AND ISNULL((SELECT T1.AssetClass FROM OITM T1 WHERE T1.ItemCode=@MainFANo AND T1.AssetGroup='M'AND T1.ItemType='F'),'')<> @AssetClass
			BEGIN 
				SET @error=1
				SET @error_message='(AMD_05_01)The Main Fixed Asset class must is same with interest fixed Asset class'
			END 				
			--The current valid cost center of main fixed asset must is same with interest fixed Asset class
			IF @FAGroup='I' AND ISNULL(@MainFANo,'')<>'' AND ISNULL((SELECT TOP 1 T1.OcrCode FROM OITM T0 LEFT JOIN ITM6 T1 ON T0.ItemCode=@MainFANo ORDER BY LineNum DESC ),'')<>ISNULL((SELECT TOP 1 T1.OcrCode FROM  OITM T0 LEFT JOIN ITM6 T1 ON T0.ItemCode=@list_of_cols_val_tab_del ORDER BY LineNum DESC ),'')
			BEGIN 
				SET @error=1
				SET @error_message='(AMD_05-02)The Main Fixed Asset cost center must is same with interest fixed Asset class!'
			END					
			-------------------------------------------------------------------
			/*
			   Coding ID:AMD_04
			   By:Jack
			   Date:20131111
			   description: Check whether the value in inventory No field is a main fixed asset, if not, then the fixed asset cannot be stored into system
			   Remark:Inventory No Validation (Main fixed asset No.)
			*/
			-------------------------------------------------------------------	
			--The code in field Main FIxed Asset No must is a valid Main Fixed Asset Code
			IF @FAGroup='I' AND (SELECT COUNT(*) FROM OITM T1 WHERE T1.ItemCode=ISNULL(@MainFANo,'') AND T1.AssetGroup='M'AND T1.ItemType='F')=0
			BEGIN 
				SET @error=1
				SET @error_message='(AMD_04)The code '+CONVERT(VARCHAR(20),ISNULL(@MainFANo,''))+' in Main Fixed Asset field is not a valid Fixed Asset master data code!'
			END 
			-----------------------------------------------------------------
			/*
			   Coding ID:AMD_06
			   By:Jack
			   Date:20131111
			   description:1.If the fixed asset code not follow the fixed asset code naming convention when adding a new fixed asset , then the fixed asset cannot be stored into system
			   Remark: Fixed Asset code Validation
			*/
			-------------------------------------------------------------------			    
			--Main fixed Asset code naming convension validation
			IF @FAGroup='M' AND LEN(@ItemCode)<>6 or SUBSTRING(@ItemCode,1,1)<>'F'
			BEGIN 
				SET @error=1
				SET @error_message='(AMD_06_01)The Main Fixed Asset Master Data code is not following naming convension !'
			END

			--The Interest fixed Asset master code naming convension validation
			IF @FAGroup='I' AND ISNULL(@MainFANo,'')<>'' AND SUBSTRING(@ItemCode,1,6)<>@MainFANo 
			BEGIN
				SET @error=1
				SET @error_message='(AMD_06_02)The Interest Fixed Asset Master Data code is not following naming convension ,the code should be '+@MainFANo+'A !'
			END	
			
	    	--Fixed asset master data code validation
	    	IF @ItemGroup='109'and @FAGroup='M'and @FAStatus='N'
			Begin 
				SELECT  @MaxCode=MAX(Convert(int,Right(t0.ItemCode,5))+1)  FROM OITM T0 WHERE T0.ItmsGrpCod='109' AND T0.AssetGroup='M' AND T0.ItemCode<>@list_of_cols_val_tab_del
				IF @MaxCode <>Convert(int,Right(@ItemCode,5))
                Begin
					SET @error=1
					SET @error_message='(AMD_06_03)The sequance number should be '+ 'F'+right('00000'+CONVERT(nvarchar(7),isnull(@MaxCode,0)),5)+'!'
				END
			End	  
			-------------------------------------------------------------------
			/*
			   Coding ID:AMD_03
			   By:Jack
			   Date:20131111
			   description: 1. If the asset group is null , then the fixed asset cannot be stored into system
							2. If the asset group is main fixed asset , but inventory No is not null, then the fixed asset cannot be stored into system
							3. If the asset group is interest fixed asset , but inventory No is null, then the fixed asset cannot be stored into system
			   Remark:Asset Group Validation
			*/
			-------------------------------------------------------------------		
			--Must assign an Asset Group for Fixed Asset Master Data
			IF ISNULL(@FAGroup,'')=''
			BEGIN 
				SET @error=1
				SET @error_message='(AMD_03_01)Please assign an appropriate Asset Group for current Fixed Asset master data !'
			END
			-- IF the Asset group is main fixed Asset , then Main fixed Asset No field must be null
			IF @FAGroup='M' AND ISNULL(@MainFANo,'')<>''
			BEGIN 
				SET @error=1
				SET @error_message='(AMD_03_02)If the Asset group is main fixed Asset , then Main fixed Asset No field must be null '
			END
						
			--Main fixed Asset code must be entered IF the current fixed Asset is an interest fixed Asset
			IF @FAGroup='I' AND ISNULL(@MainFANo,'')='' 
			BEGIN 
				SET @error=1
				SET @error_message='(AMD_03_03)If the Asset group is interest fixed Asset , then Main Fixed Asset No field must be entered a valid Fixed Asset master data code !'
			END

			-------------------------------------------------------------------
			/*
			   Coding ID:AMD_01
			   By:Jack
			   Date:20131111
			   description:If the item is a fixed asset, but it’s an inventory item or a Purchase item or a sales item , then the fixed asset cannot be stored into system
			   Remark:FA Item property Validation
			*/
			-------------------------------------------------------------------	    
	        --Fixed Asset Master Data property validation
			IF @InvntItem='Y'or @SellItem='Y' or @PrchseItem='Y'
			BEGIN 
				SET @error=1
				SET @error_message='(AMD_01)IF Item is an Fixed Asset master data ,then please set Inventory Item=N, Sell Item=N,Purchase Item=N!'
			END	
			-------------------------------------------------------------------
			/*
			   Coding ID:AMD_02
			   By:Jack
			   Date:20131111
			   description:If the item is a fixed asset, but its item Group is not ’Fixed Assets’, then the fixed asset cannot be stored into system
			   Remark:Item Group Validation
			*/
			-------------------------------------------------------------------	
	        --Fixed Asset Master Data must set 'Fixed Asset' as Item Group
			IF @ItemGroup<>'109'
			BEGIN 
				SET @error=1
				SET @error_message='(AMD_02)Please set Fixed Asset as Item Group for Fixed Asset Master Data!'
			END			   
		END
	END
END	

/**********************
   Asset Master Data-Update
**********************/
IF( @object_type='4') 
BEGIN
    IF (@transaction_type in ('U'))
    BEGIN
		-------------------------------------------------------------------
		/*
		   Coding ID:AMD_11
		   By:Jack
		   Date:20131111
		   description: Asset class, Asset group can't update after fixed asset saved into system.
		   Remark: Asset class, Asset group can't update after fixed asset saved into system.
		*/
		-------------------------------------------------------------------	
        SELECT @ItemGroup=t0.ItmsGrpCod FROM OITM t0 WHERE t0.ItemCode=@list_of_cols_val_tab_del
		--Asset Group cannot be updated ONce fixed Asset master data was added
		IF @ItemGroup='109'
		BEGIN
			SELECT @orignValue=T0.AssetGroup
			FROM AITM T0
			WHERE T0.ItemCode=@list_of_cols_val_tab_del
			AND LogInstanc=(
						     SELECT MAX(loginstanc) 
							 FROM AITM
							 WHERE ItemCode=@list_of_cols_val_tab_del
						      )

			SELECT @FAGroup=T0.AssetGroup
			FROM OITM T0
			WHERE T0.ItemCode=@list_of_cols_val_tab_del

			IF @orignValue<>@FAGroup
			BEGIN
				SET @error=1
				SET @error_message='Asset group cannot update after fixed asset saved into system!'
			END

			--Asset Class cannot be updated ONce  fixed Asset master data was added
			SELECT @orignValue=T0.AssetClass
			FROM AITM T0
			WHERE T0.ItemCode=@list_of_cols_val_tab_del
			AND LogInstanc=(
						      SELECT MAX(loginstanc) 
							 FROM AITM
							 WHERE ItemCode=@list_of_cols_val_tab_del
						     )

			SELECT @AssetClass=AssetClass
			FROM OITM
			WHERE ItemCode=@list_of_cols_val_tab_del

			IF @orignValue<>@AssetClass
			BEGIN
				SET @error=1
				SET @error_message='Asset Class cannot update after fixed asset saved into system!'
			END
		END
    END
END		 
			 
/**********************
   Item Master Data
**********************/
IF( @object_type='4') 
BEGIN       
	IF( @transaction_type IN ('U','A'))   
	BEGIN
	SELECT  @CapitalProjectID=T1.AttriTxt2,
			@Location=T0.Location,
			@AssetClass=T0.AssetClass,
			@InvntItem=T0.InvntItem,
			@SellItem=T0.SellItem,
			@PrchseItem=T0.PrchseItem,
			@ItemType=T0.ItemType,
			@ItemGroup=t0.ItmsGrpCod,
			@ItemCode=T0.ItemCode,
			@MainFANo=T0.InventryNo,
			@FAGroup=T0.AssetGroup 
	FROM OITM T0 LEFT JOIN ITM13 T1 ON T0.ItemCode=T1.ItemCode 
	WHERE T0.ItemCode=@list_of_cols_val_tab_del 	    
	    --Non fixed Asset item validation
			-------------------------------------------------------------------
			/*
			   Coding ID:IMD_01
			   By:Jack
			   Date:20131111
			   description: If the item belongs to bulk/expense item, then user should set as purchase item, but can’t set as sales item and inventory item
			   Remark:Bulk/ Expense item property validation
			*/
			-------------------------------------------------------------------	
			--Bulk/Expense Item Property validation
			IF @ItemGroup='110'
			BEGIN
                SELECT  @MaxCode=MAX(Convert(int,Right(t0.ItemCode,5))+1)  FROM OITM T0 WHERE T0.ItmsGrpCod='110'  AND T0.ItemCode<>@list_of_cols_val_tab_del
		    	--Bulk/Expense Item Property validation	        
				IF @InvntItem='Y'or @SellItem='Y' or @PrchseItem='N'
				BEGIN 
					SET @error=1
					SET @error_message='(IMD_01) If Item is an Bulk/Expense item ,then please set Inventory Item=N, Sell Item=N,Purchase Item=Y!'
				END	 
				-------------------------------------------------------------------
				/*
				   Coding ID:IMD_02
				   By:Jack
				   Date:20131111
				   description: 1. If user try to add a Bulk/expense item, but the code not follow naming convention, then cannot add and update bulk/expense item in system
								2. New item code should be the next number to the maximum one 
				   Remark:Bulk/expense item code validation
				*/
				-------------------------------------------------------------------	
				--Bulk/Expense item Code naming convension validation
				IF LEN(@ItemCode)<>6 or SUBSTRING(@ItemCode,1,1)<>'E'
				BEGIN 
					SET @error=1
					SET @error_message='(IMD_02_01)ItemCode is not following naming convension !'
				END
					
				IF (Select Count(*) FROM OITM WHERE ItemCode=@list_of_cols_val_tab_del )>1
				BEGIN 
					IF @MaxCode <>Convert(int,Right(@ItemCode,5))
					Begin
						SET @error=1
						SET @error_message='(IMD_02_02)The sequance number should be '+ 'E'+right('00000'+CONVERT(nvarchar(7),isnull(@MaxCode,0)),5)+'!'
					END
				END
			END
			-------------------------------------------------------------------
			/*
			   Coding ID:IMD_03
			   By:Jack
			   Date:20131111
			   description: If the item belongs to project item, then user should set as purchase item, but can’t set as sales item and inventory item
			   Remark:Project item master data property validation
			*/
			-------------------------------------------------------------------				
			--Project Item Validation
			IF @ItemGroup='108'
			BEGIN
		    	SELECT  @MaxCode=MAX(Convert(int,Right(t0.ItemCode,5))+1)  FROM OITM T0 WHERE T0.ItmsGrpCod='108'  AND T0.ItemCode<>@list_of_cols_val_tab_del
		    	--Project Item Property validation	        
				IF @InvntItem='Y'or @SellItem='Y' or @PrchseItem='N'
				BEGIN 
					SET @error=1
					SET @error_message='(IMD_03)If Item is a Project item ,then please set Inventory Item=N, Sell Item=N,Purchase Item=Y!'
				END	 
				-------------------------------------------------------------------
				/*
				   Coding ID:IMD_04
				   By:Jack
				   Date:20131111
				   description: 1. if project item code doesn't follow naming convention, system doesn't allow to save it in the system
								2. New item code should be the next number to the maximum one
				   Remark:Project item master data property validation
				*/
				-------------------------------------------------------------------	
				--Project item Code naming convension validation
				IF LEN(@ItemCode)<>6 or SUBSTRING(@ItemCode,1,1)<>'P'
				BEGIN 
					SET @error=1
					SET @error_message='(IMD_04_01)ItemCode is not following naming convension !'
				END	

				IF (Select Count(*) FROM OITM WHERE ItemCode=@list_of_cols_val_tab_del )>1
				BEGIN 
					IF @MaxCode <>Convert(int,Right(@ItemCode,5))
					Begin
						SET @error=1
						SET @error_message='(IMD_04_02)The sequance number should be '+ 'P'+right('00000'+CONVERT(nvarchar(7),isnull(@MaxCode,0)),5)+'!'
					END
				END
		  END
    END	
END	


/**********************
   Journal Entry
**********************/
IF( @object_type='30') 
BEGIN 
	IF( @transaction_type IN ('U','A'))   
	BEGIN
		SELECT @Count=COUNT(*) 
		FROM OJDT T0 INNER JOIN JDT1 T1 ON T0.TransId=T1.TransId 
		WHERE T0.TransId=@list_of_cols_val_tab_del

        SET @LineID=0
		WHILE @LineID <= (@Count-1)
			BEGIN

			SELECT  @CostCenter=T1.ProfitCode,
					@CostCenterRelvnt=T2.Dim1Relvnt,
					@PrjRelvnt=T2.PrjRelvnt,
					@Project=T1.Project,
					@TransType=T0.TransType,
					@Account=T1.Account,
					@TrdPrtID_JE=T1.U_TrdPrtID,
					@FunctionArea_JE=T1.U_FunctionArea, 
					@TrdPrtRel=T2.U_TrdPrtRel,
					@TrdPrtID = T2.U_TrdPrtID,
					@FunctionArea = T2.U_FunctionArea,
					@ONlyAutoTrans = T2.U_ONlyAutoTrans, 
					@LocManTran = T2.LocManTran,
					@TransCode=T1.TransCode,
					@Remark=T0.Memo,
					@CashFlowRelvnt=t2.CfwRlvnt,
					@CashFlowItem=T3.CFWId,
					@StornoToTr=T0.StornoToTr,
					@AuotStorno=T0.AutoStorno,
					@JETotalLC=T0.LocTotal,
					@JETotalSC=T0.SysTotal,
					@DebCred=(CASE WHEN T1.DebCred='C' THEN 'DebitSC' ELSE 'CreditSC' END)
			FROM OJDT T0 
			INNER JOIN JDT1 T1 ON T0.TransId=T1.TransId
			LEFT JOIN OACT T2 ON T1.Account=T2.AcctCode
			LEFT JOIN (SELECT * FROM OCFT WHERE  TransType='30') T3 ON T0.TransId=T3.JDTId and t1.line_id =t3.JDTLineId
			WHERE T0.TransId=@list_of_cols_val_tab_del AND T1.Line_ID=@LineID

			IF (@TransType<>'-3')
			Begin
				-------------------------------------------------------------------
				/*
				   Coding ID:JE_01
				   By:Jack
				   Date:20131111
				   description: 1.If one of journal entry line GL accounts is a trading Partner relative account, while no trading partner defines in GL account master data, and field ‘Trading Partner ID’ in journal entry line is null, then the JE cannot be stored into system,Except for TransCode='FX'
								2.If one of journal entry line GL accounts is not a trading Partner relative account, and field ‘Trading Partner ID’ in journal entry line is not null, then the JE cannot be stored into system
								3.If one of journal entry line GL accounts is a trading Partner relative account, and fills the value in field ‘Trading Partner ID’, check whether filled Trading Partner ID is existing in trading partner table , if not, then the JE cannot be stored into system 
				   Remark:Trading Partner ID Validation
				*/
				-------------------------------------------------------------------				     
				IF (@TrdPrtRel='Y' AND @LocManTran='N' AND ISNULL(@TrdPrtID,'')=''AND ISNULL(@TrdPrtID_JE,'')='' AND @TransCode<>'FX') 
				BEGIN
					SET @error=1
					SET @error_message='(JE_01_01)Please input Trading Partner ID into line'+CONVERT(VARCHAR(20),@LineID+1)+ ',The JE remark is'''+@Remark+ ''' !'
				END
			
				IF (@TrdPrtRel='N' AND (ISNULL(@TrdPrtID_JE,'')<>'') )
				BEGIN
					SET @error=1
					SET @error_message='(JE_01_02)Cannot assign Trading Partner ID into line'+CONVERT(VARCHAR(20),@LineID+1)+ ',The JE remark is'''+@Remark+ ''' !'
				END
			
				IF ( ISNULL(@TrdPrtID_JE,'')<>'' )
				BEGIN 
					IF( SELECT COUNT(*) FROM [@ZFTBD] T1 WHERE T1.Code=@TrdPrtID_JE)=0
					BEGIN 
						SET @error=1
						SET @error_message='(JE_01_03)Specified Trading Partner ID '+CONVERT(VARCHAR(20),@TrdPrtID_JE)+' in line'+CONVERT(VARCHAR(20),@LineID+1)+ ' is invalid ，please input a valid ID! The JE remark is'''+@Remark+ ''' !'
					END
				END
				-------------------------------------------------------------------
				/*
				   Coding ID:JE_02
				   By:Jack
				   Date:20131111
				   description: If one of GL accounts in JE is an account with “only auto transaction”, then the JE cannot be stored into system,Except for TransCode='FX'
				   Remark:G/L accounts Automatically post only Validation
				*/
				-------------------------------------------------------------------					
				IF (@OnlyAutoTrans='Y' AND @TransType='30'AND @TransCode<>'FX' )
				BEGIN
					SET @error=1
					SET @error_message='(JE_02)Cannot manually book GL Account '+CONVERT(VARCHAR(15),@Account)+' in line ' +CONVERT(VARCHAR(20),@LineID+1)+',The JE remark is'''+@Remark+ ''' !'
				END			
				-------------------------------------------------------------------
				/*
					Coding ID:JE_03
					By:Jack
					Date:20131111
					description: 1. If one of GL accounts in JE is not a project related account, but project is not null then the JE cannot be stored into system.
								 2. If one of GL accounts in JE is a project related account, but the project is null, then the JE cannot be stored into system.  Expect for TransCode='FX'    
					Remark: Project Validation
				*/
				-------------------------------------------------------------------					
				IF (@PrjRelvnt='N'AND ISNULL(@Project,'')<>''  )
				BEGIN
					SET @error=1
					SET @error_message='(JE_03_01)Cannot assign a project to a non project releated GL account'+CONVERT(VARCHAR(15),@Account)+' in line ' +CONVERT(VARCHAR(20),@LineID+1)+',The JE remark is'''+@Remark+ ''' !'
				END	
				IF (@PrjRelvnt='Y'AND ISNULL(@Project,'')='' AND @TransCode<>'FX' )
				BEGIN
					SET @error=1
					SET @error_message='(JE_03_02)Please assign a project to project releated GL account'+CONVERT(VARCHAR(15),@Account)+' in line ' +CONVERT(VARCHAR(20),@LineID+1)+' , Or Set TransCode=FX ,The JE remark is'''+@Remark+ ''' !'
				END		
				-------------------------------------------------------------------
				/*
				   Coding ID:JE_04
				   By:Jack
				   Date:20131111
				   description: 1.If one of GL accounts in JE is not a cost center related account, but cost center is not null, then the JE cannot be stored into system.     
								2.If one of GL accounts in JE is a cost center related account, but cost center is null, then the JE cannot be stored into system. Expect for TransCode='FX'  
				   Remark: Cost Center Validation
				*/
				-------------------------------------------------------------------					

				IF (@CostCenterRelvnt='N' AND  ISNULL(@CostCenter,'')<>''  )
				BEGIN
					SET @error=1
					SET @error_message='(JE_04_01)Cannot assign a cost center to a non cost center releated GL account '+CONVERT(VARCHAR(15),@Account)+' in line ' +CONVERT(VARCHAR(20),@LineID+1)+',The JE remark is'''+@Remark+ ''' !'
				END	

				IF (@CostCenterRelvnt='Y' AND  ISNULL(@CostCenter,'')='' AND @TransCode<>'FX'   )
				BEGIN
					SET @error=1
					SET @error_message='(JE_04_02)Please assign a cost center to cost center releated GL account'+CONVERT(VARCHAR(15),@Account)+' in line ' +CONVERT(VARCHAR(20),@LineID+1)+',The JE remark is'''+@Remark+ ''' !'
				END		

				-------------------------------------------------------------------
				/*
				   Coding ID:JE_07
				   By:Jack
				   Date:20140401
				   description: 1.If one of GL accounts in JE is a cash flow relevent account, and not reverse JE ,but cash flow item is  null, then the JE cannot be stored into system. Expect for TransCode='FX'     
								2.If JE is a reverse JE and TransCode='FX',and one of GL accounts in JE is a  cash flow relevent account, but cash flow item is null, then the JE cannot be stored into system.  
				   Remark: Cost Center Validation
				*/
				-------------------------------------------------------------------	
				IF (@TransType='30' and  @CashFlowRelvnt='Y' AND  ISNULL(@CashFlowItem,'')='' AND @TransCode<>'FX'   )
				BEGIN
					SET @error=1
					SET @error_message='(JE_07_01)Please assign a cash flow item for cash flow relevent GL account'+CONVERT(VARCHAR(15),@Account)+' in line ' +CONVERT(VARCHAR(20),@LineID+1)+',The JE remark is'''+@Remark+ ''' !'
				END	
				
				IF (@TransType='30' and @CashFlowRelvnt='Y' AND  ISNULL(@CashFlowItem,'')='' AND @TransCode='FX' AND ISNULL(@StornoToTr,'')<>''  )
				BEGIN
					SET @error=1
					SET @error_message='(JE_07_02)Please assign a cash flow item for cash flow relevent GL account'+CONVERT(VARCHAR(15),@Account)+' in line ' +CONVERT(VARCHAR(20),@LineID+1)+',The JE remark is'''+@Remark+ ''' !'
				END		
								-------------------------------------------------------------------
				/*
				   Coding ID:JE_08
				   By:Jack
				   Date:20140511
				   description: 1.If the reconciliation difference(LC&SC) not equal zero before reconciling,system should block this reconcilation
				   Remark: Reconciliation difference(LC&SC) Validation
				*/
				-------------------------------------------------------------------	
				IF @TransType='321' and @Remark='Manual Reconciliation Transaction' 
				BEGIN 
			        
						SET @error=1
						SET @error_message='Reconciliation difference(LC&SC) must be zero before reconciling,you need to create adjustment JE ,the difference(SC) is'''+CONVERT(VARCHAR(20),@DebCred)+' '+CONVERT(VARCHAR(20),@JETotalSC)+'''!'
				END

            END
		SET @LineID=@LineID+1
		END	

	END	
END

/**********************
   1-Journal Entry-the coding just lanuch added
**********************/
IF( @object_type='30') 
BEGIN 
	IF( @transaction_type IN ('A'))   
	BEGIN
		SELECT @Count=COUNT(*) FROM OJDT T0 INNER JOIN JDT1 T1 ON T0.TransId=T1.TransId WHERE T0.TransId=@list_of_cols_val_tab_del
        SET @LineID=0
		WHILE @LineID <= (@Count-1)
			BEGIN
			SELECT @PrintJENo=T0.U_PrintJENo,@ExternalJENo=T0.U_ExternalJENo,@CostCenter=T1.ProfitCode,@CostCenterRelvnt=T2.Dim1Relvnt, @PrjRelvnt=T2.PrjRelvnt,@Project=T1.Project,@TransType=T0.TransType,@Account=T1.Account,@TrdPrtID_JE=T1.U_TrdPrtID,@FunctionArea_JE=T1.U_FunctionArea, @TrdPrtRel=T2.U_TrdPrtRel,@TrdPrtID = T2.U_TrdPrtID,@FunctionArea = T2.U_FunctionArea,@ONlyAutoTrans = T2.U_ONlyAutoTrans, @LocManTran = T2.LocManTran 
			       FROM OJDT T0 
			       INNER JOIN JDT1 T1 ON T0.TransId=T1.TransId
			       LEFT JOIN OACT T2 ON T1.Account=T2.AcctCode
			       WHERE T0.TransId=@list_of_cols_val_tab_del AND T1.Line_ID=@LineID
-------------------------------------------------------------------
/*
   Coding ID:JE_05
   By:Jack
   Date:20131111
   description: Trading Partner ID:
				If one of GL accounts in JE  is a Trading Partner related account and control account,then set Trading partner id field as blank when adding JE into system.
				If one of GL accounts in JE  is a Trading Partner related account ,and exist trading partner ID ,then set Trading partner id field as blank when adding JE into system.
				Function Area:
				If function area field in JE is not null,then set function area field as blank when adding JE into system.
				JE Print No.:
				If JE Print No. in JE has already been existing in system,then set this field as blank when adding JE into system.
				External JE No.:
				If External JE No in JE has already been existing in system,then set this field as blank when adding JE into system.
   Remark: Trading Partner ID,Function Area，JE Print No.，External JE No. need to keep as blank when adding JE into system
*/
-------------------------------------------------------------------					
			--Set specific trading partner id field blank  
			IF ISNULL(@TrdPrtID_JE,'')<>'' AND @TrdPrtRel='Y' AND ISNULL(@TrdPrtID,'')<>''
		    BEGIN
                UPDATE JDT1  SET U_TrdPrtID='' WHERE TransId=@list_of_cols_val_tab_del
			END
			
			IF ISNULL(@TrdPrtID_JE,'')<>'' AND @TrdPrtRel='Y' AND @LocManTran='Y'
		    BEGIN
                UPDATE JDT1  SET U_TrdPrtID='' WHERE TransId=@list_of_cols_val_tab_del
			END	
			
			--Set Function Area field blank  
			IF ISNULL(@FunctionArea_JE,'')<>'' 
		    BEGIN
                UPDATE JDT1  SET U_FunctionArea='' WHERE TransId=@list_of_cols_val_tab_del
			END
			
			--Set JE Print No field blank  
			IF ISNULL(@PrintJENo,'')<>'' 
		    BEGIN
				IF ( SELECT COUNT(*) FROM OJDT T1 WHERE T1.U_PrintJENo=@PrintJENo)<>0
				BEGIN
					UPDATE OJDT SET U_PrintJENo='' WHERE TransId=@list_of_cols_val_tab_del
				END
			END
			
			--Set External JE No field blank  
			IF ISNULL(@ExternalJENo,'')<>'' 
		    BEGIN
				IF ( SELECT COUNT(*) FROM OJDT T1 WHERE T1.U_ExternalJENo=@ExternalJENo AND T1.TransId<>@list_of_cols_val_tab_del)<>0
				BEGIN
					UPDATE OJDT SET U_ExternalJENo='' WHERE TransId=@list_of_cols_val_tab_del
				END
			END			
		SET @LineID=@LineID+1
		END	
	END	
END

/**********************
   2-Journal Entry-the coding just lanuch added
**********************/
IF( @object_type='30') 
BEGIN 
-------------------------------------------------------------------
/*
   Coding ID:JE_06
   By:Jack
   Date:20140311
   description: Function Area:
				If the cost Center field in JE was updated,then set function area field as blank when updating JE into system.
*/
-------------------------------------------------------------------	
	IF( @transaction_type IN ('U'))   
	BEGIN
		DECLARE Temp_Curslr1 CURSOR FOR
	
		SELECT T0.Line_ID,T0.ProfitCode,T1.ProfitCode 
			FROM JDT1 T0 
			LEFT JOIN (SELECT TransId,Line_ID, ProfitCode 
			                  FROM AJD1 
							  WHERE LogInstanc=(SELECT MAX(LogInstanc)
							                          FROM AJD1 
													  WHERE TransId=@list_of_cols_val_tab_del))T1
			                                    ON T0.TransId=T1.TransId AND T0.Line_ID=T1.Line_ID 
            WHERE T0.TransId=@list_of_cols_val_tab_del
		
	
		OPEN Temp_Curslr1
	
		FETCH NEXT FROM Temp_Curslr1 INTO @lineid,@Costcenter,@OrignValue
		WHILE (@@FETCH_STATUS <>-1)
		BEGIN		
			IF  ISNULL(@Costcenter,'')<>ISNULL(@OrignValue,'')
			BEGIN
			   UPDATE JDT1 SET U_FunctionArea='' WHERE TransId=@list_of_cols_val_tab_del AND  Line_ID=@lineid
			END		
			FETCH NEXT FROM Temp_Curslr1 INTO @lineid,@Costcenter,@OrignValue  
		END
		CLOSE Temp_Curslr1
		DEALLOCATE Temp_Curslr1
	END
END		
				
/**********************
   AP Invoice 
   Header level validation
**********************/
IF( @object_type='18') 
BEGIN 
	IF( @transaction_type IN ('U','A'))   
	BEGIN

	    SELECT  @Canceled=T0.CANCELED, 
				@VendorRefNo=T0.NumAtCard,
				@DocCur=T0.DocCur,
				@DocType=T0.DocType,
				@InvType=T0.U_InvType,
				@PaymentTerm=T0.GroupNum,
				@PaymentMethod=T0.PeyMethod, 
				@Remark=T0.Comments
		FROM OPCH T0 
		     LEFT JOIN OPYM T2 ON T0.PeyMethod=T2.PayMethCod 
	    WHERE T0.DocEntry=@list_of_cols_val_tab_del

		IF @Canceled<>'C'	
		BEGIN
			-------------------------------------------------------------------
			/*
			   Coding ID:AP INV_01
			   By:Jack
			   Date:20131111
			   description: If 'Vendor Ref. No.' field is null, then the AP invoice cannot be recorded into system.

			   Remark: Vendor Ref. No. Validation
			*/
			-------------------------------------------------------------------	
			IF (ISNULL(@VendorRefNo ,'')='')
			BEGIN 		
				SET @error=1
				SET @error_message='(AP INV_01) Please input Invoice No into field Vendor Ref No.!'
			END			
			
			-------------------------------------------------------------------
			/*
			   Coding ID:AP INV_02
			   By:Jack
			   Date:20131111
			   description: If AP Invoice payment method is null, then the AP invoice cannot be recorded into system.

			   Remark: Payment Method validation
			*/
			-------------------------------------------------------------------	
			IF (ISNULL(@PaymentMethod,'')='')
			BEGIN 		
				SET @error=1
				SET @error_message='(AP INV_02)Please assign appropriate payment method for current Invoice!'
			END	
			-------------------------------------------------------------------
			/*
			   Coding ID:AP INV_03
			   By:Jack
			   Date:20131111
			   description: If the currency of payment method is different with invoice currency, invoice can’t store into the system.
			   Remark: Payment method and invoice currency validation
			*/
			-------------------------------------------------------------------				
			IF @PaymentMethod<>'OT_Manual'
			Begin
				IF (@DocCur NOT IN (SELECT TOP 1 T1.CurrCode FROM OPYM T0 LEFT JOIN PYM1 T1 ON T0.PayMethCod=T1.PymCode WHERE T0.PayMethCod=@PaymentMethod)) 
				BEGIN 
        			SET @error=1
					SET @error_message='(AP INV_03) The curreny of current document is different with the currency of payment method ，please check invoice currency and payment method currency!'
				END
			END
			-------------------------------------------------------------------
			/*
			   Coding ID:AP INV_04
			   By:Jack
			   Date:20131111
			   description: 1. If invoice type is ‘Debit Memo’ or ‘Non PO related Invoice’, then invoice Item/Service Type must be Services type.Otherwise AP invoice cannot be recorded into system.
							2. If invoice type is ‘PO related invoice’, then invoice Item/Service Type must be Item type.Otherwise AP invoice cannot be recorded into system.
			   Remark: Item/Services type Validation
			*/
			-------------------------------------------------------------------	      
			IF (@InvType IN ('1','2') AND @DocType<>'S')
			BEGIN 		
				SET @error=1
				SET @error_message='(AP INV_04_01)Document type must be service type when inveoice is Debit Memo or non PO Related Invoice !'
			END	

			IF (@InvType IN ('0') AND @DocType<>'I')
			BEGIN 		
				SET @error=1
				SET @error_message='(AP INV_04_01)Document type must be Item type when inveoice is PO Related Invoice !'
			END	
			-------------------------------------------------------------------
			/*
			   Coding ID:AP INV_11
			   By:Jack
			   Date:20131111
			   description: If user creates a Debit memo, then field ‘Remarks’ cannot be blank, Otherwise the Debit Memo cannot be stored into system.   
			   Remark: Remarks Validation
			*/
			-------------------------------------------------------------------	 
			IF (@InvType IN ('1') AND ISNULL(@Remark,'')='')
			BEGIN 		
				SET @error=1
				SET @error_message='(AP INV_11_01)For A/P Debit Memo,Remark is mandantory!'
			END	
		END
	END
END		

/**********************
   AP Invoice 
   Line level validation
**********************/
IF( @object_type='18') 
BEGIN 
	IF( @transaction_type IN ('U','A'))   
	BEGIN

	    SELECT @Count=COUNT(*) 
		FROM OPCH T0 
		     INNER JOIN PCH1 T1 ON T0.DocEntry=T1.DocEntry 
	    WHERE T0.DocEntry=@list_of_cols_val_tab_del

        SET @LineID=0

		WHILE @LineID <= (@Count-1)
			BEGIN

			SELECT  @Canceled=T0.CANCELED, 
					@PrjRelvnt=T3.PrjRelvnt,
					@CostCenterRelvnt=T3.Dim1Relvnt,
					@Project=T1.Project,
					@CostCenter=T1.OcrCode,
					@DocType=T0.DocType,
					@InvType=T0.U_InvType,
					@BaseDocType=T1.BaseType,
					@BaseDocNo=t1.BaseEntry,
					@BaseLine=T1.BaseLine,
					@orignInvNo=T1.U_originalInvNo,
					@orignLineNo=T1.U_originalLineNo
			FROM OPCH T0 
			INNER JOIN PCH1 T1 ON T0.DocEntry=T1.DocEntry 
			LEFT JOIN OPYM T2 ON T0.PeyMethod=T2.PayMethCod 
			LEFT JOIN OACT T3 ON T1.AcctCode=T3.AcctCode
			WHERE T0.DocEntry=@list_of_cols_val_tab_del AND T1.LineNum=@LineID

				IF @Canceled<>'C'
				BEGIN	

					-------------------------------------------------------------------
					/*
					   Coding ID:AP INV_05
					   By:Jack
					   Date:20131111
					   description: 1.3-match
									2.If invoice is based on GR, then this field must be set as ‘PO Related Invoice’
									3.If invoice is a debit memo, then this field must be set as ‘Debit Memo’
									4.If invoice is standalone invoice like freight, duty, etc, then this field must be as ‘Non PO Related Invoice’
									Otherwise AP invoice cannot be recorded into system.
					   Remark: Invoice type Validation
					*/
					-------------------------------------------------------------------	      
					IF (@BaseDocType NOT IN ('20','-1'))
					BEGIN	
						SET @error=1
						SET @error_message='(AP INV_05_01)AP Invoice just could be created reference to GR or standalone '
					END
					
					IF (@InvType IN ('0') AND @BaseDocType NOT IN ('20'))
					BEGIN 
						SET @error=1
						SET @error_message='(AP INV_05_02)PO Related Invoice must reference to GR'
					END	
						
					IF (@InvType IN ('1','2') AND @BaseDocType NOT IN ('-1'))
					BEGIN 
						SET @error=1
						SET @error_message='(AP INV_05_03)Non PO Related Invoice and Debit Memo just could be created standalone'
					END	

					-------------------------------------------------------------------
					/*
					   Coding ID:AP INV_06
					   By:Jack
					   Date:20131111
					   description: If the invoice is part of procurement process, derived cost center and project from goods receipt can’t update in the invoice
					   Remark:Cost center and project can’t update in PO related invoice
					*/
					-------------------------------------------------------------------	  					
					--Project Validation
					IF ((SELECT T0.Project FROM PDN1 T0 WHERE T0.DocEntry=@BaseDocNo AND T0.LineNum=@BaseLine)<>@Project) AND (@InvType='0')
					BEGIN 
						SET @error=1
						SET @error_message='(AP INV_06_01)Cannot change dervierd project in line '+CONVERT(VARCHAR(20),@LineID+1)+'!'
					END
					--Cost Center Validation
					IF ((SELECT T0.OcrCode FROM PDN1 T0 WHERE T0.DocEntry=@BaseDocNo AND T0.LineNum=@BaseLine)<>@CostCenter) AND (@InvType='0')
					BEGIN 
						SET @error=1
						SET @error_message='(AP INV_06_02)Cannot change dervierd Cost Center in line '+CONVERT(VARCHAR(20),@LineID+1)+'!'
					END

					-------------------------------------------------------------------
					/*
					   Coding ID:AP INV_07
					   By:Jack
					   Date:20131111
					   description: In Non-PO related invoice and Debit Memo
									1.if corresponding GL account is not controlled by cost center, cost center can’t be filled.
									2.If corresponding GL account is not controlled by project, project can’t be filled.
									3.if corresponding GL account is controlled by cost center, cost center must be filled.
									4.If corresponding GL account is controlled by project, project must be filled.  
					   Remark:Project / Cost center validation for Non-PO related invoice and Debit Memo
					*/
					-------------------------------------------------------------------	  
					--IF GL Account is non cost center related account , then this line cannot enter project				
					IF (ISNULL(@CostCenter,'')<>'' )
					BEGIN				
						IF (@CostCenterRelvnt='N'AND @InvType IN ('1','2')  )
						BEGIN 
							SET @error=1
							SET @error_message='(AP INV_07_01)Cannot input cost center to a non cost center related account in line '+CONVERT(VARCHAR(20),@LineID+1)+'!'
						END	
					END	
					--IF GL Account is non project related account , then this line cannot enter project
					IF (ISNULL(@Project ,'')<> '' )
					BEGIN				
						IF (@PrjRelvnt='N'AND @InvType IN ('1','2') )
						BEGIN 
							SET @error=1
							SET @error_message='(AP INV_07_02)Cannot input project to a non project related account in line '+CONVERT(VARCHAR(20),@LineID+1)+'!'
						END	
					END		

					--if corresponding GL account is controlled by cost center, cost center must be filled.		
					IF (ISNULL(@CostCenter,'')='' )
					BEGIN				
						IF (@CostCenterRelvnt='Y' )
						BEGIN 
							SET @error=1
							SET @error_message='(AP INV_07_01) Please input cost center to a cost center related account in line '+CONVERT(VARCHAR(20),@LineID+1)+'!'
						END	
					END	
					--IF GL Account is project related account , then this line must enter project
					IF (ISNULL(@Project ,'')= '' )
					BEGIN				
						IF (@PrjRelvnt='Y')
						BEGIN 
							SET @error=1
							SET @error_message='(AP INV_07_02) Please input project to a project related account in line '+CONVERT(VARCHAR(20),@LineID+1)+'!'
						END	
					END	
														
					-------------------------------------------------------------------
					/*
					   Coding ID:AP INV_08
					   By:Jack
					   Date:20131111
					   description: 1.If invoice type not is ‘Debit Memo’, and the two fields are not null, then the AP invoice cannot be recorded into system.
									2.If invoice type is ‘Debit Memo’, and the two fields are null, then the AP invoice cannot be recorded into system.
					   Remark: Original Invoice No. / Line No. Validation
					*/
					-------------------------------------------------------------------	  
					--original Inv No must be null in PO related Invoice 
					IF (ISNULL(@orignInvNo,'') <> '') AND (@InvType IN ('0','2'))
					BEGIN 
						SET @error=1
						SET @error_message='(AP INV_08_01)Cannot input originInvNo and originLineNo for Non Debit Memo document, line '+CONVERT(VARCHAR(20),@LineID+1)+'!'
					END
						
					--original line no must be null in PO related Invoice 
					IF (ISNULL(@orignLineNo,'') <> '') AND (@InvType IN ('0','2'))
					BEGIN 
						SET @error=1
						SET @error_message='(AP INV_08_02)Cannot input originInvNo and originLineNo for Non Debit Memo document, line '+CONVERT(VARCHAR(20),@LineID+1)+'!'
					END
					--original Inv No must be entered in Debit Memo
					IF (ISNULL(@orignInvNo ,'') = '') AND (@InvType='1')
					BEGIN 
						SET @error=1
						SET @error_message='(AP INV_08_03)Please input originInvNO and orignLineNo for Debit Memo, line '+ CONVERT(VARCHAR(20),@LineID+1)+'!'
					END
						
					--original line no must be enterd in Debit Memo
					IF (ISNULL(@orignLineNo,'') = '') AND (@InvType='1')
					BEGIN 
						SET @error=1
						SET @error_message='(AP INV_08_04)Please input originInvNO and orignLineNo for Debit Memo, line'+ CONVERT(VARCHAR(20),@LineID+1)+'!'
					END
				END
			SET @LineID=@LineID+1
		END	        
	END
END	
		
/**********************
   AP Invoice 
   Payment Block validation
**********************/
IF( @object_type='18') 
BEGIN 
	-------------------------------------------------------------------
	/*
		Coding ID:AP INV_09
		By:Jack
		Date:20131111
		description: 1.	If user creates a Debit memo, then must block payment, Otherwise the AP Invoice cannot be stored into system.  
                     2.	Only the user with authorization ‘Release Payment Authorization’ could release the payment for current document (AP Invoice & Debit Memo). 

			 
		Remark: Payment Block validation
	*/
	-------------------------------------------------------------------	  
	--Adding
	IF( @transaction_type IN ('A'))   
	BEGIN
	    SELECT  @Canceled=T0.CANCELED,
				@InvType=T0.U_InvType,
				@PayBlock=T0.PayBlock
			
		FROM OPCH T0 
		WHERE T0.DocEntry=@list_of_cols_val_tab_del

		IF @Canceled<>'C'	
		BEGIN
			IF (@InvType='1') AND @PayBlock<>'Y'
			BEGIN 		 		
				SET @error=1
				SET @error_message='(AP INV_09_01)Please bolck payment and specify appropriate resean for Debit Memo !'
			END
		END
		UPDATE OPCH SET [U_PayBlock_Log]=PayBlock WHERE DocEntry=@list_of_cols_val_tab_del
	END

	--Updating
	IF( @transaction_type IN ('U'))   
	BEGIN
	     SELECT  @Canceled=T0.CANCELED,
				 @PayBlock=T0.PayBlock,
				 @OrignValue=T0.[U_PayBlock_Log],
				 @ReleasePayment=T1.U_ReleasePayment
		FROM OPCH T0 
		     LEFT JOIN OUSR T1 ON T0.UserSign2=T1.INTERNAL_K 
		WHERE T0.DocEntry=@list_of_cols_val_tab_del

		IF @Canceled<>'C'	
		BEGIN
			-- Release Payment
			IF  @PayBlock='N' AND @OrignValue='Y'
			BEGIN 
			    IF @ReleasePayment<>'Y'
			    BEGIN
					SET @error=1
					SET @error_message='(AP INV_09_02)You have no permision to release payment for current document ,Please contact system admin!'
				END
			END
		END
		UPDATE OPCH SET [U_PayBlock_Log]=PayBlock WHERE DocEntry=@list_of_cols_val_tab_del
	END
	
END	

/**********************
   AP Invoice 
   Tolerance validation
**********************/
IF( @object_type='18') 
BEGIN 
	IF( @transaction_type IN ('A')) 
	BEGIN
	   
		-------------------------------------------------------------------
		/*
		   Coding ID:AP INV_10
		   By:Jack
		   Date:20131111
		   description: Validation logic：
						SUM (INV line Amount, Group by Base GR Doc No + Base GR Line No)- SUM (Credit Memo line Amount, Group by Base INV Doc No + Base INV Line No)+Sum(Debit Memo line Amount, Group by Original INV Doc No + Original INV Line No )<=(SUM(GR line Amount )-SUM(Goods Return line Amount, Group by Base GR Doc No + Base GR Line No ))*(1+ MaxPcntDiff)  
						AND
						SUM (INV line Amount, Group by Base GR Doc No + Base GR Line No)- SUM (Credit Memo line Amount, Group by Base INV Doc No + Base INV Line No) +Sum(Debit Memo line Amount, Group by Original INV Doc No + Original INV Line No )<=(SUM(GR line Amount )-SUM(Goods Return line Amount, Group by Base GR Doc No + Base GR Line No ))+ MaxAmtDiff)
		   Remark:AP Invoice Tolerance validation
		*/
		-------------------------------------------------------------------	  
		DECLARE Temp_Curslr1 CURSOR FOR
	
		SELECT t1.BaseLine,t1.BaseEntry,T1.linetotal,T1.BaseType,T1.linenum,t2.U_IsActiv,ISNULL(t2.U_tolValue,0) ,ISNULL(t2.U_tolRate,0) ,t3.Payblock
		FROM pch1 t1 
		LEFT JOIN opch t3 ON t1.docentry=t3.docentry, [@ZCTLC] t2 
		WHERE T2.U_toleDoc='18'  AND t1.docentry=@list_of_cols_val_tab_del
	
		OPEN Temp_Curslr1
	
		FETCH NEXT FROM Temp_Curslr1 INTO @baseline,@basedocno,@linetotal,@basedoctype,@lineid,@IsActiv,@tolValue,@tolRate,@Payblock 
		WHILE (@@FETCH_STATUS <>-1)
		BEGIN
		
			IF  @BaseDocType='20' AND @IsActiv='Y' 
			BEGIN
				SET @GRlinetotal=(SELECT 
										ISNULL(LineTotal,0) 
								   FROM PDN1 
								   WHERE DocEntry =@BaseDocNo 
								         AND LineNum =@baseline
									) -- the linetotal of base GR LINE

				SET @PINVlinetotal=(SELECT 
										ISNULL(SUM(T1.LineTotal),0) 
									FROM PCH1 T1 
									     LEFT JOIN OPCH T2 ON T1.DocEntry=T2.Docentry 
									WHERE T1.BaseEntry =@BaseDocNo 
									      AND T1.BaseLine =@baseline  
										  AND T2.CANCELED='N'
									) --Subtotal the linetotal of current inv line and the historic invoiced linetotal which base on the GR line
				
				SET @PCMlinetotal=(SELECT 
										ISNULL(SUM(T2.LineTotal),0) 
								   FROM PCH1 T1 
										 LEFT JOIN RPC1 t2 ON t2.BaseEntry =T1.DocEntry AND t2.BaseLine =T1.LineNum 
										 LEFT JOIN ORPC T3 ON T1.DocEntry=T3.DocEntry	
								   WHERE T1.BaseEntry =@basedocno 
									      AND T1.BaseLine =@baseline 
										  AND T3.CANCELED='N') 

				SET @CGRlinetotal=(SELECT 
				                        Round((T1.LineTotal/t1.InvQty)*t2.InvQty,2)
								   FROM PDN1 T1 
								        INNER JOIN PCH1 T2 ON T1.DocEntry=T2.BaseEntry AND T1.LineNum=T2.BaseLine 
								   WHERE T1.DocEntry =@BaseDocNo 
								        AND T1.LineNum =@baseline 
										AND T2.DocEntry=@list_of_cols_val_tab_del)	

				SET @CINVlinetotal=(SELECT
				                        ISNULL(T1.LineTotal,0)
									FROM PCH1 T1 
									     LEFT JOIN OPCH T2 ON T1.DocEntry=T2.DocEntry 
									WHERE T1.BaseEntry =@BaseDocNo 
									      AND T1.BaseLine =@baseline 
										  AND T1.DocEntry=@list_of_cols_val_tab_del )
														

				IF (@CINVlinetotal-@CGRlinetotal)>@tolValue OR (@CINVlinetotal-@CGRlinetotal)>(@CGRlinetotal*(@tolRate/100))
				BEGIN 
				    IF @PayBlock<>'Y'
					BEGIN
						SET @error=1
						SET @error_message='(AP INV_10_01) Currrent AP Invoice Document line '+ CONVERT(VARCHAR(20),@lineid+1)+' amount exceed the tolerance limited ,please block payment for current AP Invoice!'
						--SET @error_message=	'r'+convert(varchar(20),@CINVlinetotal) +convert(varchar(20),@CGRlinetotal)
						--SET @error_message='Document line '+ CONVERT(NVARCHAR(20),@PINVlinetotal-@GRlinetotal-@PCMlinetotal)+' exceed tolerance ,please block payment for current AP Invoice!'
					END
				END	
				ELSE 
				IF @PINVlinetotal-@PCMlinetotal-@GRlinetotal>@tolValue or @PINVlinetotal-@PCMlinetotal-@GRlinetotal> @GRlinetotal*(@tolRate/100)
				BEGIN
					IF @PayBlock<>'Y'
					BEGIN
						SET @error=1
						SET @error_message='(AP INV_10_02)Invoiced amount of current document line '+ CONVERT(VARCHAR(20),@lineid+1)+' so far exceed tolerance limited ,please block payment for current AP Invoice!'
						--SET @error_message=	'r'+convert(varchar(20),@PINVlinetotal) +convert(varchar(20),@PCMlinetotal)+convert(varchar(20),@GRlinetotal)
						--SET @error_message='Document line '+ CONVERT(NVARCHAR(20),@PINVlinetotal-@GRlinetotal-@PCMlinetotal)+' exceed tolerance ,please block payment for current AP Invoice!'
					END		
				END	
			END		
			FETCH NEXT FROM Temp_Curslr1 INTO @baseline,@BaseDocNo,@linetotal,@basedoctype,@lineid,@IsActiv,@tolValue,@tolRate,@Payblock  
		END
		CLOSE Temp_Curslr1
		DEALLOCATE Temp_Curslr1
	END
END
					
/**********************
   AP Credit Memo
   Header level validation
**********************/
IF( @object_type='19') 
BEGIN 
	IF( @transaction_type IN ('U','A'))   
	BEGIN
	    
	    SELECT @DocDate=T0.DocDate,
		@Canceled=T0.CANCELED, 
		@VendorRefNo=T0.NumAtCard,
		@DocCur=T0.DocCur,
		@DocType=T0.DocType,
		@InvType=T0.U_InvType,
		@PaymentTerm=T0.GroupNum,
		@PaymentMethod=T0.PeyMethod,
		@PayBlock=T0.PayBlock 
		FROM ORPC T0  
		WHERE T0.DocEntry=@list_of_cols_val_tab_del

		IF @Canceled<>'C'
		BEGIN 	
			-------------------------------------------------------------------
			/*
			   Coding ID:AP CM_01
			   By:Jack
			   Date:20131111
			   description: If Vendor Ref No. field is null, then the credit memo cannot be recorded into system.
			   Remark: Vendor Ref. No. Validation
			*/
			-------------------------------------------------------------------						
			IF (ISNULL(@VendorRefNo,'') ='')
			BEGIN 		
				SET @error=1
				SET @error_message='(AP CM_01)Please input Invoice No. into field Vendor Ref No.!'
	        END			
			-------------------------------------------------------------------
			/*
			   Coding ID:AP CM_02
			   By:Jack
			   Date:20131111
			   description: If AP Credit Memo payment term not is ‘0 -Days’, then the AP Credit Memo cannot be recorded into system.
			   Remark: Payment Term Validation
			*/
			-------------------------------------------------------------------				
		    IF (@PaymentTerm <> '-1')
			BEGIN 		
				SET @error=1
				SET @error_message='(AP CM_02)Please assign 0-Days to payment term for current Credit Memo!'
	        END	  
			-------------------------------------------------------------------
			/*
			   Coding ID:AP CM_03
			   By:Jack
			   Date:20131111
			   description: Currency in payment method should be consistent with document currency, otherwise it will be failed to include in the payment wizard.
			   Remark: Payment method currency and document currency validation
			*/
			-------------------------------------------------------------------			        
	        IF @PaymentMethod<>'OT_Manual'
			Begin
				IF (@DocCur NOT IN (SELECT TOP 1 T1.CurrCode FROM OPYM T0 LEFT JOIN PYM1 T1 ON T0.PayMethCod=T1.PymCode WHERE T0.PayMethCod=@PaymentMethod)) 
				BEGIN 
            		SET @error=1
					SET @error_message='(AP CM_03)The curreny of current document is different with the currency of current payment method !'
				END
			END 
		END    
	END
END		

/**********************
   AP Credit Memo
   Line level validation
**********************/	
IF( @object_type='19') 
BEGIN 
	IF( @transaction_type IN ('U','A'))   
	BEGIN
	DECLARE @NoInvtryMv  VARCHAR(2)		
	
		SELECT @Count=COUNT(*) FROM orPC T0 INNER JOIN RPC1 T1 ON T0.DocEntry=T1.DocEntry WHERE T0.DocEntry=@list_of_cols_val_tab_del
        SET @LineID=0
		WHILE @LineID <= (@Count-1)
			BEGIN
				SELECT  @Canceled=T0.CANCELED, 
						@PrjRelvnt=T3.PrjRelvnt,
						@CostCenterRelvnt=T3.Dim1Relvnt,
						@InvntItem=T2.InvntItem,
						@NoInvtryMv =T1.NoInvtryMv,
						@Project=T1.Project,
						@CostCenter=T1.OcrCode,
						@DocType=T0.DocType,
						@InvType=T0.U_InvType,
						@BaseDocType=T1.BaseType,
						@BaseDocNo=t1.BaseEntry,
						@BaseLine=T1.BaseLine,
						@orignInvNo=T1.U_originalInvNo,
						@orignLineNo=T1.U_originalLineNo,
						@Remark=T0.Comments
				FROM ORPC T0 
				INNER JOIN RPC1 T1 ON T0.DocEntry=T1.DocEntry 
				LEFT JOIN OITM T2 ON T1.ItemCode=T2.ItemCode
				LEFT JOIN OACT T3 ON T1.AcctCode=T3.AcctCode 
				WHERE T0.DocEntry=@list_of_cols_val_tab_del AND T1.LineNum=@LineID	
											
			   IF @Canceled<>'C'
			   BEGIN  
					-------------------------------------------------------------------
					/*
					   Coding ID:AP CM_04
					   By:Jack
					   Date:20131111
					   description: 1.	If the item in credit memo line is an inventory management item and the current credit memo line is based on specific invoice line, then this checkbox must be checked, otherwise credit memo can’t store into the system.
                                    2.	If the item in credit memo line is inventory management item and the current credit memo is standalone, then system doesn’t allow this document be adding into the system.

					   Remark: Without Quantity Posting Validation
					*/
					-------------------------------------------------------------------		 
				   IF (@InvntItem='Y')
				   BEGIN 	
						IF (@NoInvtryMv='N')
						BEGIN 
							IF (@BaseDocType='18')
							BEGIN	
								SET @error=1
								SET @error_message='(AP CM_4_01)If item in credit memo is inventory managed item and the credit memo is based on AP invoice, then the checkbox Without Qty Posting must be checked, Line '+ CONVERT(VARCHAR(20),@LineID+1)+'!'
							END
						END
						
						IF (@NoInvtryMv='Y')
						BEGIN 
							IF (@BaseDocType='-1')
							BEGIN	
								SET @error=1
								SET @error_message='(AP CM_04_01)If item in credit memo is inventory managed item and credit memo is standalone,then the document cannot be added'
							END
						END
					END
					-------------------------------------------------------------------
					/*
					   Coding ID:AP CM_05
					   By:Jack
					   Date:20131111
					   description: if credit memois dependent on other documents(GRT or AP Inv), cost center and project can't be updated
					   Remark: Cost center and project can’t update in dependent credit memo
					*/
					-------------------------------------------------------------------		
					--IF AP Credit Memo dependent on AP Invoice ,then cost center and project can't be updated
					IF @BaseDocType='18'
					BEGIN
					    --Project Validation
						IF ((SELECT T0.Project FROM PCH1 T0 WHERE T0.DocEntry=@BaseDocNo AND T0.LineNum=@BaseLine)<>@Project)
						BEGIN 
							SET @error=1
							SET @error_message='(AP CM_05_01) Cannot change derived project in line '+CONVERT(VARCHAR(20),@LineID+1)+'!'
						END
						
						--Cost Center Validation
						IF ((SELECT T0.OcrCode FROM PCH1 T0 WHERE T0.DocEntry=@BaseDocNo AND T0.LineNum=@BaseLine)<>@CostCenter)
						BEGIN 
							SET @error=1
							SET @error_message='(AP CM_05_02)Cannot change derived cost center in line '+CONVERT(VARCHAR(20),@LineID+1)+'!'
						END
					END
					
					--IF AP Credit Memo dependent on Goods Return ,then cost center and project can't be updated
					IF @BaseDocType='21'
					BEGIN
					    --Project Validation
						IF ((SELECT T0.Project FROM RPD1 T0 WHERE T0.DocEntry=@BaseDocNo AND T0.LineNum=@BaseLine)<>@Project)
						BEGIN 
							SET @error=1
							SET @error_message='(AP CM_05_03)Cannot change derived project in line '+CONVERT(VARCHAR(20),@LineID+1)+'!'
						END
						
						--Cost Center Validation
						IF ((SELECT T0.OcrCode FROM RPD1 T0 WHERE T0.DocEntry=@BaseDocNo AND T0.LineNum=@BaseLine)<>@CostCenter)
						BEGIN 
							SET @error=1
							SET @error_message='(AP CM_05_04)Cannot change derived cost center in line '+CONVERT(VARCHAR(20),@LineID+1)+'!'
						END
					END
				
					IF @BaseDocType='-1'
					BEGIN
					-------------------------------------------------------------------
					/*
					   Coding ID:AP CM_08
					   By:Jack
					   Date:20131111
					   description: If credit memo is standalone , then the Remark cannot be null 
					   Remark: Remark Validation
					*/
					-------------------------------------------------------------------		
						 --IF Credit Memo is standalone, then the Remark cannot be null 
						IF (ISNULL(@Remark,'')='')
						BEGIN				
							SET @error=1
							SET @error_message='(AP CM_06_07)For Standalone A/P Credit Memo,Remark is mandantory!'
						END
					-------------------------------------------------------------------
					/*
					   Coding ID:AP CM_09
					   By:Jack
					   Date:20131111
					   description: If credit memo is standalone , then the document type must be service type 
					   Remark: Remark Validation
					*/
					-------------------------------------------------------------------		
						--IF Credit Memo is standalone, then the document type must be service type
						IF (@DocType<>'S')
						BEGIN				
							SET @error=1
							SET @error_message='(AP CM_06_06)Standalone AP Credit Memo must be service type !'
						END


				   -------------------------------------------------------------------
					/*
					   Coding ID:AP CM_06
					   By:Jack
					   Date:20131111
					   description: In standalone AP Credit Memo;
				1. If the GL account in document line is not controlled by cost center, then field cost center can’t be filled.
				2. If the GL account in document line is not controlled by project, then field project can’t be filled.
				3. If the GL account in document line is controlled by cost center, then field cost center must be filled.
				4. If the GL account in document line is controlled by project, then field project must be filled.
					   Remark: Cost center and project validation in independent credit memo
					*/
					-------------------------------------------------------------------		
						--IF GL Account is non project related account , then this line cannot enter project
						IF (ISNULL(@Project,'')<>'')
						BEGIN				
							IF (@PrjRelvnt='N'  )
							BEGIN 
								SET @error=1
								SET @error_message='(AP CM_06_01) Cannot input project to a non project related account in line '+CONVERT(VARCHAR(20),@LineID+1)+'!'
							END	
						END
						--IF GL Account is non cost center related account , then this line cannot enter project				
						IF (ISNULL(@CostCenter,'')<>'')
						BEGIN				
							IF (@CostCenterRelvnt='N' )
							BEGIN 
								SET @error=1
								SET @error_message='(AP CM_06_02)Cannot input cost center to a non cost center related account in line '+CONVERT(VARCHAR(20),@LineID+1)+'!'
							END	
						END
						--If corresponding GL account is controlled by cost center, cost center must be filled.		
						IF (ISNULL(@CostCenter,'')='' )
						BEGIN				
							IF (@CostCenterRelvnt='Y' )
							BEGIN 
								SET @error=1
								SET @error_message='(AP CM_06_03) Please input cost center to a cost center related account in line '+CONVERT(VARCHAR(20),@LineID+1)+'!'
							END	
						END	
						--IF GL Account is project related account , then this line must enter project
						IF (ISNULL(@Project ,'')= '' )
						BEGIN				
							IF (@PrjRelvnt='Y')
							BEGIN 
								SET @error=1
								SET @error_message='(AP CM_06_04) Please input project to a project related account in line '+CONVERT(VARCHAR(20),@LineID+1)+'!'
							END	
						END	
                         
					END
				END	
				SET @LineID=@LineID+1
			END
	END
END	
	
/**********************
   AP Credit Memo
   Tolerance validation
**********************/		
IF( @object_type='19') 
BEGIN
	IF( @transaction_type IN ('A')) 
	BEGIN 
		-------------------------------------------------------------------
		/*
		   Coding ID:AP CM_07
		   By:Jack
		   Date:20131111
		   description:Validation Logic：
						SUM (Credit Memo line Amount, Group by Base Goods Return Doc No + Base Goods Return Line No) >=(SUM(Goods Return line Amount, Group by Base Goods Return Doc No + Base Goods Return Line No))*(1+ MaxPcntDiff)  
						AND 
						SUM (Credit Memo line Amount, Group by Base Goods Return Doc No + Base Goods Return Line No) >=(SUM(Goods Return line Amount, Group by Base Goods Return Doc No + Base Goods Return Line No)) + MaxAmtDiff)
		   Remark:AP Credit Memo Tolerance Validation
		*/
		-------------------------------------------------------------------		
		DECLARE Temp_Curslr1 CURSOR FOR
	
		SELECT baseline,baseentry,linetotal,BaseType,linenum,t2.U_IsActiv,ISNULL(t2.U_tolValue,0) ,ISNULL(t2.U_tolRate,0) ,t3.Payblock
		FROM RPC1 t1 
		INNER JOIN ORPC t3 ON t1.docentry=t3.docentry, [@ZCTLC] t2 
		WHERE T2.U_toleDoc='19' AND t1.docentry=@list_of_cols_val_tab_del
	
	
		OPEN Temp_Curslr1
	
		FETCH NEXT FROM Temp_Curslr1 INTO @baseline,@basedocno,@linetotal,@basedoctype,@lineid,@IsActiv,@tolValue,@tolRate,@Payblock 
		WHILE (@@FETCH_STATUS <>-1)
		BEGIN
		
			IF @basedoctype='21' AND @IsActiv='Y'
			BEGIN
			    --
				SET @GRtnlinetotal=(
				                     SELECT ISNULL(SUM(LineTotal),0) 
									 FROM RPD1 
									 WHERE DocEntry =@BaseDocNo 
									       AND LineNum =@baseline
										   )
				SET @PCMlinetotal=(
				                    SELECT ISNULL(SUM(T1.LineTotal),0) 
									FROM RPC1 T1 
									     LEFT JOIN ORPC T2 ON T1.DocEntry=T2.DocEntry 
									WHERE T1.BaseEntry =@BaseDocNo 
									      AND T1.BaseLine =@baseline 
										  AND T2.CANCELED='N'
										  )
 			
				SET @CGRtnlinetotal=(
				                     SELECT 
									  Round((T1.LineTotal/t1.InvQty)*t2.InvQty,2)
									 FROM RPD1 T1
									 INNER JOIN RPC1 T2 ON T1.DocEntry=T2.BaseEntry AND T1.LineNum=T2.BaseLine
									 WHERE T1.DocEntry =@BaseDocNo 
									       AND T1.LineNum =@baseline
										  AND T2.DocEntry=@list_of_cols_val_tab_del
										   )   
										               
				SET @CCMlinetotal=(
				                     SELECT ISNULL(T1.LineTotal,0) 
									 FROM RPC1 T1
									 WHERE  T1.BaseEntry=@BaseDocNo
											and T1.BaseLine=@BaseLine
									        and T1.DocEntry =@list_of_cols_val_tab_del
									        --AND T1.LineNum =@lineid
										 
								   )   	
      ----                  --this script is used for debug 
					 --   SET @error=1
						--SET @error_message=isnull(CONVERT(varchar(20),@lineid),'a')+'  '+isnull(CONVERT(varchar(20),@CCMlinetotal),'a')+' ' + isnull(CONVERT(varchar(20),@CGRtnlinetotal),'b')+' '+ isnull(CONVERT(varchar(20),@PCMlinetotal),'c')+' '+isnull(CONVERT(varchar(20),@GRtnlinetotal),'d')
						
						
				IF (@GRtnlinetotal-@PCMlinetotal)>@tolValue  or (@GRtnlinetotal-@PCMlinetotal)>(@GRtnlinetotal*@tolRate/100)
				BEGIN
					IF @PayBlock<>'Y'
					BEGIN 
						SET @error=1
						SET @error_message='(AP CM_07_01)Credited amount of current document line '+ CONVERT(VARCHAR(20),@lineid+1)+' so far exceed tolerance limited ,please block payment for current AP Credit Memo!'
						--SET @error_message='Document line '+ CONVERT(VARCHAR(20),@GRtnlinetotal-@PCMlinetotal)+' exceed tolerance ,please block payment for current AP Credit Memo!'
					END
				END	
														   			
				--ELSE 
				IF (@CGRtnlinetotal-@CCMlinetotal)>@tolValue OR (@CGRtnlinetotal-@CCMlinetotal)>(@GRtnlinetotal*@tolRate/100)
				BEGIN 
				    IF @PayBlock<>'Y'
					BEGIN 
						SET @error=1
						SET @error_message='(AP CM_07_02)Currrent AP Credit Memo Document line '+ CONVERT(VARCHAR(20),@lineid+1)+' amount exceed the tolerance limited ,please block payment for current AP Credit Memo!'
						--SET @error_message='Document line '+ CONVERT(VARCHAR(20),@GRtnlinetotal-@PCMlinetotal)+' exceed tolerance ,please block payment for current AP Credit Memo!'
					END
				END 		
			END		
			FETCH NEXT FROM Temp_Curslr1 INTO @baseline,@BaseDocNo,@linetotal,@basedoctype,@lineid,@IsActiv,@tolValue,@tolRate,@Payblock   
		END
		CLOSE Temp_Curslr1
		DEALLOCATE Temp_Curslr1
	END
END

/**********************
   AP Down Payment Request 
**********************/		
IF( @object_type IN ('204')) 
BEGIN 
	-------------------------------------------------------------------
	/*
	   Coding ID:AP DPR_01
	   By:Jack
	   Date:20131111
	   description: 1.If user creates an AP Down Payment Request, then must set block payment and specify appropriate reason，otherwise the AP Down Payment Request cannot be stored into system.  
					2.If user updates an AP Down Payment Request to block payment,then must specify appropriate reason,otherwise the AP Down Payment Request cannot be stored into system.
					3.If user updates an AP Down Payment Request to release payment,then must specify appropriate reason，otherwise the AP Down Payment Request cannot be stored into system.  
	   Remark:Payment block validation 
	*/
	-------------------------------------------------------------------	  
	IF( @transaction_type IN ('A'))   
	BEGIN
	    SELECT  @Canceled=T0.CANCELED,
				@InvType=T0.U_InvType,
				@PayBlock=T0.PayBlock,
				@PayBlockRef=t0.PayBlckRef
		FROM ODPO T0 
		WHERE T0.DocEntry=@list_of_cols_val_tab_del

		IF @Canceled<>'C'	
		BEGIN
			IF @PayBlock<>'Y' 
			BEGIN 		 		
				SET @error=1
				SET @error_message='(AP DPR_001_01)Please bolck payment and specify appropriate resean for AP Down Payment Request!'
			END
		END
		UPDATE ODPO SET [U_PayBlock_Log]=PayBlock WHERE DocEntry=@list_of_cols_val_tab_del
	END
	
	IF( @transaction_type IN ('U'))   
	BEGIN

	    SELECT  @Canceled=T0.CANCELED,
				@PayBlock=T0.PayBlock,
				@OrignValue=T0.[U_PayBlock_Log],
				@ReleasePayment=T1.U_ReleasePayment
		FROM ODPO T0 
		     LEFT JOIN OUSR T1 ON T0.UserSign2=T1.INTERNAL_K 
		WHERE T0.DocEntry=@list_of_cols_val_tab_del

		IF @Canceled<>'C'	
		BEGIN		
			--Release Payment 
			IF @PayBlock='N' AND @OrignValue='Y'
			BEGIN 
			    IF @ReleasePayment<>'Y'
			    BEGIN
					SET @error=1
					SET @error_message='(AP DPR_001_02)You have no permision to release payment for current document ,Please contact system admin!'
				END
			END
		END
		UPDATE ODPO SET [U_PayBlock_Log]=PayBlock WHERE DocEntry=@list_of_cols_val_tab_del
	END
END	

/**********************
   AP Goods Receipt PO
**********************/	
IF( @object_type='20') 
BEGIN 
	IF( @transaction_type IN ('A')) 
	BEGIN
		-------------------------------------------------------------------
		/*
		   Coding ID:AP GR_001
		   By:Jack
		   Date:20131111,Update 20140110
		   description: Update the reference PO No and PO line No into fields ‘PO No.’ and ‘PO Line No’ in specific GR line
		   Remark:Update reference PO No. and PO Line No. 
		*/
		-------------------------------------------------------------------	  
		DECLARE Temp_Curslr1 CURSOR FOR
	
		SELECT baseline,Linenum,BaseRef,BaseType
		FROM PDN1 t1 
		WHERE t1.docentry=@list_of_cols_val_tab_del
	
		OPEN Temp_Curslr1
	
		FETCH NEXT FROM Temp_Curslr1 INTO @baseline,@lineID,@basedocno,@basedoctype

		WHILE (@@FETCH_STATUS <>-1)
		BEGIN
	
			UPDATE PDN1 
			SET U_PONo=@BaseDocNo,
			    U_POLineNo=CONVERT(Varchar(20),@BaseLine+1) 
			where docentry=@list_of_cols_val_tab_del and LineNum=@LineID
        
			FETCH NEXT FROM Temp_Curslr1 INTO @baseline,@lineID,@basedocno,@basedoctype
		END
		Close Temp_Curslr1
		Deallocate Temp_Curslr1
	END
END


/**********************
   Outgoing Payments
**********************/	
IF( @object_type='46') 
BEGIN 
	IF( @transaction_type IN ('U','A'))   
	BEGIN	
		-------------------------------------------------------------------
		/*
		   Coding ID:Outgoing Payment_01
		   By:Jack
		   Date:20131111,Update 20140110
		   description: Payment blockded document cannot be pay out
		   Remark:Payment Blocked Document validation
		*/
		-------------------------------------------------------------------	 
		SELECT @Count=COUNT(*) FROM OVPM T0 INNER JOIN VPM2 T1 ON T0.DocNum=T1.DocNum  WHERE T0.DocEntry=@list_of_cols_val_tab_del
        SET @LineID=0
		WHILE @LineID <= (@Count-1)
			BEGIN
				SELECT  
				@Canceled=T0.Canceled,
				@InvType=T1.InvType,
				@BaseDocNO=T1.baseAbs
				FROM OVPM T0 
				INNER JOIN VPM2 T1 ON T0.DocNum=T1.DocNum 
				WHERE T0.DocEntry=@list_of_cols_val_tab_del AND T1.InvoiceId=@LineID
            IF @Canceled='N'
			BEGIN 
				IF @InvType='18'--A/P Invoice
				Begin 
				   IF (Select PayBlock from OPCH where DocEntry=@BaseDocNo)='Y'
				   Begin 
						SET @error=1
						SET @error_message='(Outgoing Payment_01_01) The selected Invoice in line  '+CONVERT(VARCHAR(20),@LineID+1)+' was blocked payment!'
				   End
				End

				IF @InvType='30'--Journal Entry
				Begin 
				   IF (Select count(*) from JDT1 where PayBlock='Y' and TransId=@BaseDocNo)>0
				   Begin 
						SET @error=1
						SET @error_message='(Outgoing Payment_01_02) The selected Journal Entry in line  '+CONVERT(VARCHAR(20),@LineID+1)+' was blocked payment!'
				   End
				End

				IF @InvType='19'--A/P Credit Memo
				Begin 
				   IF (Select count(*) from ORPC where PayBlock='Y' and DocEntry=@BaseDocNo)>0
				   Begin 
						SET @error=1
						SET @error_message='(Outgoing Payment_01_03) The selected Credit Memo in line  '+CONVERT(VARCHAR(20),@LineID+1)+' was blocked payment!'
				   End
				End

				IF @InvType='204'--A/P Down Payment Request
				Begin 
				   IF (Select count(*) from ODPO where PayBlock='Y' and DocEntry=@BaseDocNo)>0
				   Begin 
						SET @error=1
						SET @error_message='(Outgoing Payment_01_04) The selected Downpayment request in line  '+CONVERT(VARCHAR(20),@LineID+1)+' was blocked payment!'
				   End
				End
			END
			SET @LineID=@LineID+1
		END
	END
END	













/*MM:modifycation by 2014.01.12*/
/*------------------------------------------------------- Validation - MM  ----------------------------------------------------*/
declare @m_rowcount as int
declare @m_currline as int
declare @m_rows as int
declare @m_rows2 int
declare @m_code as varchar(3)
declare @m_orincode as varchar(3)
declare @m_itemcode as varchar(20)
declare @m_cardcode as varchar(20)
declare @m_reqQTY as numeric(20,4)
declare @m_pqty as numeric(20,4)
declare @m_orinprice as numeric(20,6)
declare @m_orincurrency as varchar(6)
declare @m_unitprice as numeric(19,6)
declare @m_currency as varchar(4)
declare @m_ManBtchNum as varchar(1)
declare @m_ManSerNum as varchar(1)
declare @m_docnum as varchar(20)
declare @m_postdate as date
declare @m_agentry as varchar(20)
declare @m_agline as varchar(20)
declare @m_baseline varchar(10)
declare @m_basedocnum varchar(20)
declare @m_openqty numeric(10,4)
declare @m_validQTYBYRate numeric(20,4)
declare @m_validQTYBYValue numeric(20,4)
declare @m_qty numeric(20,4)
declare @m_tRate numeric(20,4)
declare @m_tValue numeric(20,4)
declare @m_rqty as numeric(20,4)
declare @m_cc varchar(60)
declare @m_docdate date
declare @m_prjcode varchar(60)
declare @m_doctype varchar(2)
declare @m_ItmsGrpCod varchar(6)
declare @m_InvUoM varchar(10)
declare @m_PRInvUoM varchar(10)
declare @m_reqdate date
declare @m_hisqty as numeric(10,2)
declare @m_docentry varchar(20)
declare @m_date1 date
declare @m_date2 date
declare @m_cdQTY as numeric(10,4)
/***********************************************************************
*****************************Item Master Data***************************
***********************************************************************/
if (@object_type = '4') and @transaction_type in ('U')
	Begin

		
		-----------------------------------------------------------------
		/*
			Coding ID:oitm_002
			By:Will
			Date:20131217
			description: Chemical/Fiture/Gage/Direct item/Tooling must be inventory item
			Remark:Coding
		*/
		-----------------------------------------------------------------
		set @m_rows=0
		select @m_rows=count(*)
		from oitm 
		where ItemCode=@list_of_cols_val_tab_del
		and ItmsGrpCod in ('101','102','103','104','105','106','107')
		and InvntItem='N'
		and validfor='Y'
		if @m_rows>0
		begin
		   set @error=1
		   set @error_message='(oitm_002)The item must be warehouse item'
		   SELECT @error, @error_message
		   return
		end

		

		-----------------------------------------------------------------
		/*
			Coding ID:oitm_003
			By:Will
			Date:20131217
			description: Chemical item must managed by B/N	
			Remark:Coding
		*/
		-----------------------------------------------------------------
		set @m_rows=0
		select @m_rows=count(*)
		from oitm t0 
		where t0.ItemCode=@list_of_cols_val_tab_del
		and t0.ItmsGrpCod in ('101')
		and t0.ManBtchNum='N'
		and validfor='Y'
		if @m_rows>0
		begin
		   set @error=1
		   set @error_message='(oitm_003)The item must be batch management.'
		   SELECT @error, @error_message
		   return

		end

		-------------------------------------------------------------------
		/*
			Coding ID:oitm_005
			By:Will
			Date:20131217
			description: Chemical/Fiture/Gage/Tooling cost must be 0
			Remark:Coding
		*/
		-------------------------------------------------------------------
		set @m_rows=0
		select @m_rows=count(*)
		from oitm t0 inner join oitw t1
		on t0.itemcode=t1.itemcode
		where t0.ItemCode=@list_of_cols_val_tab_del
		and t0.ItmsGrpCod in ('101','102','103','107')
		and (t0.AvgPrice<>0 or t1.AvgPrice<>0)
		and validfor='Y'
		if @m_rows>0
		begin
		   set @error=1
		   set @error_message='(oitm_005)The item cost must be zero.'
		   SELECT @error, @error_message
		   return
		end

		

		-----------------------------------------------------------------
		/*
			Coding ID:oitm_006
			By:Will
			Date:20131220
			description: The UoM name in Inventory Tab is mandatory information for inventory item
			Remark:Coding
		*/
		-----------------------------------------------------------------
		set @m_rows=0
		select @m_rows=count(*)
		from oitm t0 
		where t0.ItemCode=@list_of_cols_val_tab_del
		and t0.InvntItem='Y'
		and t0.InvntryUom is null
		and validfor='Y'
		if @m_rows>0
		begin
		   set @error=1
		   set @error_message='(oitm_006)The UoM name in inventory tab is mandatory for warehoused managed item.'
		   SELECT @error,@error_message
		   return
		end
		
		-----------------------------------------------------------------
		/*
			Coding ID:oitm_007
			By:Will
			Date:20131222
			description: Standard evaluation method only
			Remark:Coding
		*/
		-----------------------------------------------------------------
		set @m_rows=0
		select @m_rows=count(*)
		from oitm t0 
		where t0.ItemCode=@list_of_cols_val_tab_del
		and t0.evalsystem<>'S'
		and t0.ItmsGrpCod NOT in ('109')
		and validfor='Y'
		if @m_rows>0
		begin
		   set @error=1
		   set @error_message='(oitm_007)Item valuation method must be standard price.'
		   SELECT @error, @error_message
		   return
		end

		-----------------------------------------------------------------
		/*
			Coding ID:oitm_008
			By:Will
			Date:20131223
			description: check the Purchase Uom convert to Inv. UoM must equal to the setting in BEAS UoM convertor.
			Remark:Coding
		*/
		-----------------------------------------------------------------
		set @m_rows=0
		select @m_rows=count(*)
		from oitm t0 inner join beas_me_umr t1
		on t0.BuyUnitMsr=t1.me1_id
		and t0.InvntryUom=t1.me2_id
		where t0.itemcode=@list_of_cols_val_tab_del
		and ISNUMERIC(t1.umrformel)=1
		and t0.NumInBuy<>(case when ISNUMERIC(t1.umrformel)=1 then t1.umrformel else 0 end)
		and t0.InvntItem='Y'
		and validfor='Y'
		if @m_rows>0
		begin
			
			set @error=1
			set @error_message='(oitm_008)The conversion factor of purchase UoM vs. inventory UoM is incorrect. Please correct.'
			SELECT @error, @error_message
			return
		end

		-----------------------------------------------------------------
		/*
			Coding ID:oitm_009
			By:Will
			Date:20140116
			description: the buyer information in item master data is mandatory
			Remark:Coding
			
			Update by: Robin
			Date:20140805
			description: If the PrcrmntMtd is not B in Item master, then skip this validation
			Remark:Coding
		*/
		-----------------------------------------------------------------
		set @m_rows=0
		select @m_rows=count(*)
		from oitm t0 
		where t0.itemcode=@list_of_cols_val_tab_del
		--and t0.InvntItem='Y'
		and t0.sww is null
		and t0.ItmsGrpCod not in ('109','108','110') /*Vince, 20140317, add 108&110*/
		and validfor='Y'
		and PrcrmntMtd='B'
		if @m_rows>0
		begin
			
			set @error=1
			set @error_message='(oitm_009)Buyer information is mandatory '
			select @error, @error_message
			return
		end


	End
 
 /***********************************************************************
**********************BusinessPartner Master Data***********************
***********************************************************************/
if (@object_type = '2') and @transaction_type in ('A','U')
Begin
	-------------------------------------------------------------------
	/*
		Coding ID:ocrd_001
		By:Will
		Date:20131126
		description: Customer code prefix must be C
		Remark:Coding
	*/
	-------------------------------------------------------------------  
    set @m_rowcount=0
	select @m_rowcount=count(*)
	from ocrd
	where cardtype='C'
	and left(cardcode,1)<>'C'
	and cardcode=@list_of_cols_val_tab_del
	if @m_rowcount>0
	begin
	   	set @error=1
		set @error_message='(ocrd_001)The prefix of customer code must be C.'
		SELECT @error, @error_message
		return
	end

	-------------------------------------------------------------------
	/*
		Coding ID:ocrd_002
		By:Will
		Date:20131126
		description: Employee prefix must be U
		Remark:Coding
	*/
	-------------------------------------------------------------------
	set @m_rowcount=0
	select @m_rowcount=count(*)
	from ocrd
	where cardtype='S'
    and left(cardcode,1)<>('U')
	and cardcode=@list_of_cols_val_tab_del
	and GroupCode in('104') /*Employee*/
	
	if @m_rowcount>0
	begin
	   	set @error=1
		set @error_message='(ocrd_002)The prefix of vendor code must be U when BP group is employee.'
		SELECT @error, @error_message
		return
	end
	
	-------------------------------------------------------------------
	/*
		Coding ID:ocrd_004
		By:Will
		Date:20131126
		description: Vendor code prefix must be V
		Remark:Coding
	*/
	-------------------------------------------------------------------
	set @m_rowcount=0
	select @m_rowcount=count(*)
	from ocrd
	where cardtype='S'
    and left(cardcode,1)<>('V')
	and cardcode=@list_of_cols_val_tab_del
	and GroupCode not in ('104')
	if @m_rowcount>0
	begin
	   	set @error=1
		set @error_message='(ocrd_004)The prefix of vendor code must be V.'
		SELECT @error, @error_message
		return
	end

	-------------------------------------------------------------------
	/*
		Coding ID:ocrd_003
		By:Will
		Date:20131126
		description: the Certification ID has to be filled when cert.type was filled.
		Remark:Coding
	*/
	-------------------------------------------------------------------
	set @m_rowcount=0
	select @m_rowcount=count(*)
	from ocrd
	where cardcode=@list_of_cols_val_tab_del
	and U_m_CertfcTyp is not null
	and U_m_CertfcId is null 
	if @m_rowcount>0
	begin
	   	set @error=1
		set @error_message='(ocrd_003)Certification ID must be maintained when certification type is filled.'
		SELECT @error, @error_message
		return
	end

End

if (@object_type = '2') and @transaction_type in ('U')
Begin
-------------------------------------------------------------------
/*
   Coding ID:ocrd_004
   By:Will
   Date:20131126
   description: the BP group can not be changed when BP was added
   Remark:Coding
*/
-------------------------------------------------------------------
     select @m_orincode=GroupCode
     from ACRD 
     where CardCode=@list_of_cols_val_tab_del
     and LogInstanc=(
                       select MAX(loginstanc) 
						 from ACRD
						 where CardCode=@list_of_cols_val_tab_del
					 )

	select @m_code=GroupCode
    from Ocrd
    where CardCode=@list_of_cols_val_tab_del

    if @m_orincode<>@m_code
    begin
       set @error=1
	   set @error_message='(ocrd_004)Business partner group cannot be changed after it is added.'
	   select @error,@error_message 
	   return
    end

-------------------------------------------------------------------
/*
   Coding ID:ocrd_005
   By:Will
   Date:20131126
   description: the BP type can not be changed when BP was added
   Remark:Coding
*/
-------------------------------------------------------------------
    select @m_orincode=CardType
     from ACRD 
     where CardCode=@list_of_cols_val_tab_del
     and LogInstanc=(
                       select MAX(loginstanc) 
						 from ACRD
						 where CardCode=@list_of_cols_val_tab_del
					 )

	select @m_code=CardType
    from Ocrd
    where CardCode=@list_of_cols_val_tab_del

    if @m_orincode<>@m_code
    begin
       set @error=1
	   set @error_message='(ocrd_005)Business partner type cannot be changed after it is added.'
	   select @error,@error_message 
	   return
    end

End

/***********************************************************************
*****************************Blanket Agreement***************************
***********************************************************************/
if (@object_type = '1250000025') and (@transaction_type in ('A','U'))
Begin

-------------------------------------------------------------------
/*
   Blanket Agreement lines validations
*/
-------------------------------------------------------------------	
	set @m_rowcount=0
	select @m_rowcount=count(*)
	from OOAT t0 inner join oat1 t1
	on t0.AbsID=t1.AgrNo
	where t0.absid=@list_of_cols_val_tab_del
	
	set @m_currline=0
	while @m_currline<=@m_rowcount
	begin /*while begin*/

			-------------------------------------------------------------------
			/*
			   Coding ID:BA_01
			   By:Will
			   Date:20131127
			   description: MM check in blanket agreement
			   Remark:Coding
			*/
			-------------------------------------------------------------------	
			set @m_rows=0
			select @m_rows=count(*)
			from OOAT t0 inner join oat1 t1
			on t0.AbsID=t1.AgrNo inner join OITM t2
			on t1.ItemCode =t2.ItemCode inner join OITB t3
			on t2.ItmsGrpCod =t3.ItmsGrpCod
			where t3.U_m_MM='Y'
			and t2.U_m_mm='N'
			and t1.AgrLineNum=@m_currline+1
			and t0.absid=@list_of_cols_val_tab_del
			if @m_rows>0
			begin
			    select @m_itemcode=t1.ItemCode
				from OOAT t0 inner join oat1 t1
				on t0.AbsID=t1.AgrNo inner join OITM t2
				on t1.ItemCode =t2.ItemCode inner join OITB t3
				on t2.ItmsGrpCod =t3.ItmsGrpCod
				where t3.U_m_MM='Y'
				and t2.U_m_mm='N'
				and t1.AgrLineNum=@m_currline+1
				and t0.absid=@list_of_cols_val_tab_del
				set @error=1
				set @error_message='(BA_01)The Item No. '+@m_itemcode+' has not got confirmation from MM in item master as required.'
				set @m_currline=@m_rowcount+1
			end

			

			set @m_currline=@m_currline+1


	end /*while end*/

-------------------------------------------------------------------
/*
   Coding ID:BA_04
   By:Will
   Date:20131127
   description: The blanket agreement will be block when BP was be block
   Remark:Coding
*/
-------------------------------------------------------------------	
	set @m_rowcount=0
	select @m_rowcount=COUNT(*)
	from OOAT t0 inner join ocrd t1
	on t0.BpCode=t1.CardCode
	where u_m_bsnssblk='Y'
	and t0.absid=@list_of_cols_val_tab_del
	if @m_rowcount>0
	begin
		set @error=1
		set @error_message='(BA_04)The vendor is blocked for business transactions.'
		select @error,@error_message 
		return

	end 

-------------------------------------------------------------------
/*
   Coding ID:BA_05
   By:Will
   Date:20131127
   description: The blanket agreement should be general type
   Remark:Coding
*/
-------------------------------------------------------------------	
	set @m_rowcount=0
	select @m_rowcount=COUNT(*)
	from OOAT t0 inner join ocrd t1
	on t0.BpCode=t1.CardCode
	where t0.type<>'G'/*General Blanket Agreement */
	and t0.absid=@list_of_cols_val_tab_del

	if @m_rowcount>0
	begin
		set @error=1
		set @error_message='(BA_05)The Agreement type in general Tab must be General'
		select @error,@error_message
		return

	end 
-------------------------------------------------------------------
/*
   Coding ID:BA_06
   By:Will
   Date:20131127
   description: The blanket agreement should be general type
   Remark:Coding
*/
-------------------------------------------------------------------	
	set @m_rowcount=0
	select @m_rowcount=COUNT(*)
	from OOAT t0 inner join oat1 t1
	on t0.AbsID=t1.AgrNo
	where t0.absid=@list_of_cols_val_tab_del
	and isnumeric(t1.freetxt)=0
	and t1.freetxt is not null
	if @m_rowcount>0
	begin
		set @error=1
		set @error_message='(BA_06)Only numeric value can be entered in additional plan quantity field.'
		select @error,@error_message
		return

	end 

	-------------------------------------------------------------------
/*
   Coding ID:BA_07
   By:Will
   Date:20131127
   description: Cannot modify additional planned quantity approved Blanket agreement
   Remark:Coding
*/
-------------------------------------------------------------------	
	set @m_rowcount=0
	select @m_rowcount=count(*)
	from OOAT t0 inner join oat1 t1
	on t0.AbsID=t1.AgrNo 
	left outer join 
	aoat t2 inner join aoa1 t3
	on t2.AbsID=t3.AgrNo 
	and t2.LogInstanc=t3.LogInstanc
	on t0.AbsID=t3.AgrNo 
	and t1.AgrLineNum=t3.AgrLineNum
	where t0.absid=@list_of_cols_val_tab_del
	and t2.LogInstanc in (select max(tt.loginstanc) 
						from  aoat tt
						where tt.AbsID=@list_of_cols_val_tab_del)
	and t3.FreeTxt<>t1.FreeTxt
	and t0.Status='A'
	if @m_rowcount>0
	begin
		set @error=1
		set @error_message='(BA_07)Additional plan quantity cannot be modified when blanket agreement status is approved.'
		select @error,@error_message
		return

	end

	-------------------------------------------------------------------
	/*
		Coding ID:BA_08
		By:Vince
		Date:20140310
		description: Update End Date and Start Date in related special price
		Remark:Coding
	*/
	-------------------------------------------------------------------	
	IF (SELECT Number FROM OOAT WHERE AbsID=@list_of_cols_val_tab_del) IN (SELECT DISTINCT U_m_agid FROM SPP1)
	BEGIN

			UPDATE SPP1 SET FromDate=(SELECT StartDate FROM OOAT WHERE AbsID=@list_of_cols_val_tab_del)
				WHERE U_m_agid=(SELECT Number FROM OOAT WHERE AbsID=@list_of_cols_val_tab_del)

			UPDATE SPP1 SET ToDate =(
										SELECT 
										CASE WHEN ISNULL(TermDate,'')='' THEN EndDate
											WHEN ISNULL(TermDate,'')<>'' THEN TermDate END
										FROM OOAT WHERE AbsID=@list_of_cols_val_tab_del )
				WHERE U_m_agid=(SELECT Number FROM OOAT WHERE AbsID=@list_of_cols_val_tab_del)

	END






End

/***********************************************************************
*****************************Source List********************************
***********************************************************************/
if (@object_type = 'ZMSLD') and (@transaction_type in ('A','U'))
Begin
     
	-------------------------------------------------------------------
	/*
	Coding ID:Sourcelist_001
	By:Will
	Date:20131127
	description: the item code is mandatory
	Remark:Coding
	*/
	-------------------------------------------------------------------
		set @m_rowcount=0
		select @m_rowcount=COUNT(*) 
		from [@ZMSLD] t0 inner join [@ZMSL1] t1
		on t0.DocEntry=t1.DocEntry
		where t0.DocEntry=@list_of_cols_val_tab_del
		and (t0.U_Itemcode is null or LEN(t0.u_itemcode)<=0)
		and t0.docentry=@list_of_cols_val_tab_del
		if @m_rowcount>0
		begin
			set @error=1
			set @error_message='(Sourcelist_001)Item code is mandatory.'
			select @error,@error_message
			return
		end

	-------------------------------------------------------------------
	/*
	Coding ID:Sourcelist_002
	By:Will
	Date:20131127
	description: the BP code is mandatory
	Remark:Coding
	*/
	-------------------------------------------------------------------
		set @m_rowcount=0
		select @m_rowcount=COUNT(*) 
		from [@ZMSLD] t0 inner join [@ZMSL1] t1
		on t0.DocEntry=t1.DocEntry
		where t0.DocEntry=@list_of_cols_val_tab_del
		and (t1.U_Vendorcode is null or LEN(t1.U_Vendorcode)<=0)
		and t0.docentry=@list_of_cols_val_tab_del
		if @m_rowcount>0
		begin
			set @error=1
			set @error_message='(Sourcelist_002)Vendor code is mandatory.'
			select @error,@error_message 
			return
		end


	-------------------------------------------------------------------
	/*
	Coding ID:Sourcelist_003
	By:Will
	Date:20131127
	description: valid date validation
	Remark:Coding
	*/
	-------------------------------------------------------------------
		set @m_rowcount=0
		select @m_rowcount=COUNT(*) 
		from [@ZMSLD] t0 inner join [@ZMSL1] t1
		on t0.DocEntry=t1.DocEntry
		where t0.DocEntry=@list_of_cols_val_tab_del
		and t1.U_ValidFrom>t1.U_ValidTo
		and t0.docentry=@list_of_cols_val_tab_del
		if @m_rowcount>0
		begin
			set @error=1
			set @error_message='(Sourcelist_003)Valid to date cannot be earlier than valid from date.'
			select @error,@error_message 
			return
		end


		-------------------------------------------------------------------
		/*
		Coding ID:Sourcelist_005(ABCD)
		By:Will
		Date:20131222
		description: One item in one period is not overlap for one optional vendor
		              One item in one period is not overlap for one perferred vendor
		Remark:Coding
		*/
		-------------------------------------------------------------------
		declare @m_lineid int
		DECLARE UC CURSOR FOR
		SELECT t0.u_itemcode
		,t1.u_vendorcode
		,t1.u_status
		,t1.u_validfrom
		,t1.u_validto
		,t1.lineid
		from [@zmsld] t0 inner join [@zmsl1] t1
		on t0.docentry=t1.docentry
		where t0.docentry=@list_of_cols_val_tab_del 

		OPEN UC
		FETCH NEXT FROM UC INTO @m_itemcode,@m_cardcode,@m_code,@m_date1,@m_date2,@m_lineid
		WHILE @@FETCH_STATUS=0
		BEGIN
				
				
				set @m_rows=0
				SELECT @m_rows=count(*)
				from [@zmsld] t0 inner join [@zmsl1] t1
				on t0.docentry=t1.docentry
				where t0.u_itemcode=@m_itemcode
				--and t1.u_vendorcode=@m_cardcode
				and @m_date1 between t1.u_validfrom and t1.u_validto
				and t1.lineid<>@m_lineid
				and t1.u_status=@m_code
				and t1.u_status='P'
				and t0.docentry=@list_of_cols_val_tab_del
				if @m_rows>0
				begin
				     set @error=1
				     set @error_message='(Sourcelist_005C)Overlap is found in valid from date for preferred vendor '+@m_cardcode+'. Please check and correct.'
				     select @error,@error_message
				end
				set @m_rows=0
				SELECT @m_rows=count(*)
				from [@zmsld] t0 inner join [@zmsl1] t1
				on t0.docentry=t1.docentry
				where t0.u_itemcode=@m_itemcode
				--and t1.u_vendorcode=@m_cardcode
				and @m_date2 between t1.u_validfrom and t1.u_validto
				and t1.lineid<>@m_lineid
				and t1.u_status=@m_code
				and t1.u_status='P'
				and t0.docentry=@list_of_cols_val_tab_del
				if @m_rows>0
				begin
				     set @error=1
				     set @error_message='(Sourcelist_005D)Overlap is found in valid to date for preferred vendor '+@m_cardcode+'. Please check and correct.'
				     select @error,@error_message
				end
				
				FETCH NEXT FROM UC INTO @m_itemcode,@m_cardcode,@m_code,@m_date1,@m_date2,@m_lineid
		END

		CLOSE UC
		DEALLOCATE UC

        

End

if (@object_type = 'ZMSLD') and (@transaction_type in ('A'))
Begin
	-------------------------------------------------------------------
/*
   Coding ID:Sourcelist_004
   By:Will
   Date:20131127
   description: one item only have one source list
   Remark:Coding
*/
-------------------------------------------------------------------	
		set @m_rowcount=0
		select @m_rowcount=COUNT(*)
		from [@ZMSLD] t0
		where t0.U_Itemcode =(
							  select distinct U_Itemcode
							  from [@ZMSLD]
							  where DocEntry=@list_of_cols_val_tab_del
							)
		
		if @m_rowcount>1
		begin

				set @error=1
				set @error_message='(Sourcelist_004)The item already exists in source list, one item one source list '
				select @error,@error_message 
				return
		end







End

/***********************************************************************
*****************************Special Price for BP***********************
***********************************************************************/
if (@object_type = '7') and (@transaction_type in ('A','U'))
Begin
-------------------------------------------------------------------
/*
Coding ID:OSPP_001
By:Will
Date:20131128
description: the Price should be filled at Period Discount form
Remark:Coding
*/
-------------------------------------------------------------------	
set @m_rowcount=0
select @m_rowcount=count(*)
from spp1 t1
where t1.CardCode+char(9)+t1.ItemCode =@list_of_cols_val_tab_del
if @m_rowcount<=0 
begin
	set @error=1
	set @error_message='(OSPP_001)Set period price and linked blanket agreement first'
	select @error,@error_message 
	return
end
else
begin
		set @m_currline=0
		while @m_currline<=@m_rowcount-1
		begin /*while begin*/
			-------------------------------------------------------------------
			/*
			Coding ID:OSPP_002
			By:Will
			Date:20131128
			description: Blanket agreement must be filled and price in period discound form is also be filled.
			Remark:Coding
			*/
			-------------------------------------------------------------------	
			select @m_docnum =spp1.U_m_agid
			from spp1
			where CardCode+char(9)+ItemCode =@list_of_cols_val_tab_del
			and LINENUM=@m_currline
			if len(@m_docnum)=0
			begin
				set @error=1
				set @error_message='(OSPP_002)Blanket agreement number is mandatory.'
				select @error,@error_message 
				return
			end
			else
			begin
						-------------------------------------------------------------------
						/*
						Coding ID:OSPP_003
						By:Will
						Date:20131128
						description: the linked Blanket agreement validate by vendor and item
						Remark:Coding
						*/
						-------------------------------------------------------------------	
						select @m_docnum=spp1.U_m_agid
						,@m_itemcode=spp1.ItemCode
						,@m_cardcode=spp1.CardCode   
						from spp1
						where CardCode+char(9)+ItemCode =@list_of_cols_val_tab_del
						and LINENUM=@m_currline

				
						select @m_rows2=count(*)
						from ooat t0 inner join oat1 t1
						on t0.AbsID=t1.AgrNo 
						where t0.Number=CONVERT(NUMERIC(19,0),@m_docnum)  /*Vince, 20140306,Add convert*/ 
						and t1.ItemCode=@m_itemcode
						and t0.BpCode =@m_cardcode  
						if @m_rows2<=0
						begin
								
								set @error=1
								set @error_message='(OSPP_003)Blanket agreement number is incorrect. Please make sure the vendor and item are selected correctly.'
								select @error,@error_message 
								return
						end
						else
						begin
								
								-------------------------------------------------------------------
								/*
								Coding ID:OSPP_004
								By:Will
								Date:20131128
								description: Update the start data and end data in special price for BP based on linked blanket agreement ID
								Remark:Coding
								*/
								-------------------------------------------------------------------	
								update spp1
								set spp1.FromDate = (
														select StartDate
														from ooat 
														where number =(
																			select U_m_agid 
																			from spp1 
																			where CardCode+char(9)+ItemCode =@list_of_cols_val_tab_del
																			and spp1.LINENUM=@m_currline
																	   )
														)
									,spp1.ToDate = (
														select 
														CASE WHEN isnull(TermDate,'')='' then EndDate   /*vince, 20140310, add case formula to judge the end date*/
														when isnull(TermDate,'')<>'' then TermDate end
														from ooat 
														where number =(
																	select U_m_agid 
																	from spp1 
																	where CardCode+char(9)+ItemCode =@list_of_cols_val_tab_del
																	and spp1.LINENUM=@m_currline
																	)
														)
									where CardCode+char(9)+ItemCode =@list_of_cols_val_tab_del
									and spp1.LINENUM=@m_currline

						end

			end
			 set @m_currline=@m_currline+1
		end /*while end*/
end

		-------------------------------------------------------------------
		/*
		Coding ID:OSPP_005
		By:Will
		Date:20131216
		description: Special price can't refer to price list
		Remark:Coding
		*/
		-------------------------------------------------------------------	
		set @m_rows=0
		select @m_rows=count(*)  
		from ospp t0 left outer join spp1 t1 
		on t0.ItemCode=t1.ItemCode
		and t0.CardCode=t1.CardCode 
		where t0.ListNum<>0 or isnull(t1.ListNum,0)<>0
		and  t0.CardCode+char(9)+t0.ItemCode =@list_of_cols_val_tab_del
		if @m_rows>0
		begin
			set @error=1
			set @error_message='(OSPP_005)Price list field value must be set to ''Without price list'' for special price for BP.'
			select @error,@error_message 
			return
		end

		-------------------------------------------------------------------
		/*
		Coding ID:OSPP_006
		By:Will
		Date:20131216
		description: At least define period price price
		Remark:Coding
		*/
		-------------------------------------------------------------------	
		set @m_rows=0
		select @m_rows=count(*)  
		from ospp t0 left outer join spp1 t1 
		on t0.ItemCode=t1.ItemCode
		and t0.CardCode=t1.CardCode 
		where isnull(t1.price,0)=0 
		and  t0.CardCode+char(9)+t0.ItemCode =@list_of_cols_val_tab_del
		if @m_rows>0
		begin
			set @error=1
			set @error_message='(OSPP_006)At least define unit price in Period Discounds window'
			select @error,@error_message 
			return
		end

		-------------------------------------------------------------------
		/*
		Coding ID:OSPP_007
		By:Will
		Date:20131216
		description: the basic special price should not defined
		Remark:Coding
		*/
		-------------------------------------------------------------------	
		set @m_rows=0
		select @m_rows=count(*)  
		from ospp t0 left outer join spp1 t1 
		on t0.ItemCode=t1.ItemCode
		and t0.CardCode=t1.CardCode left outer join spp2 t2
		on t0.itemcode=t2.ItemCode 
		and t0.CardCode=t2.CardCode 
		where isnull(t0.price,0)>0
		and  t0.CardCode+char(9)+t0.ItemCode =@list_of_cols_val_tab_del
		if @m_rows>0
		begin
			set @error=1
			set @error_message='(OSPP_007)No price should be maintained basic special price.'
			select @error,@error_message 
			return
		end

		-------------------------------------------------------------------
		/*
		Coding ID:OSPP_008
		By:Will
		Date:20131216
		description: define quantity stage price when quantity great than 0
		Remark:Coding
		*/
		-------------------------------------------------------------------	
		set @m_rows=0
		select @m_rows=count(*)  
		from ospp t0 left outer join spp1 t1 
		on t0.ItemCode=t1.ItemCode
		and t0.CardCode=t1.CardCode 
		left outer join spp2 t2
		on t0.itemcode=t2.ItemCode 
		and t0.CardCode=t2.CardCode
		and t1.ListNum=t2.SPP1LNum
		where isnull(t2.price,0)=0
		and t2.Amount<>0
		and  t0.CardCode+char(9)+t0.ItemCode =@list_of_cols_val_tab_del
		if @m_rows>0
		begin
			set @error=1
			set @error_message='(OSPP_008)At least define unit price in Volume Discound window'
			select @error,@error_message 
			return
		end




End

/***********************************************************************
***********************Purchase Request (UDO)************************
***********************************************************************/
if (@object_type='PR') and (@transaction_type in ('A','U'))
Begin
     
			DECLARE UC CURSOR FOR
			SELECT t0.docentry
			,t1.u_itemcode
			,t1.LineId 
			from [@ZMPRD] t0 inner join [@ZMPR1] t1
			on t0.DocEntry=t1.docentry 
			where t0.docentry=@list_of_cols_val_tab_del
			OPEN UC
			FETCH NEXT FROM UC INTO @m_docentry,@m_itemcode,@m_currline
			WHILE @@FETCH_STATUS=0
			BEGIN
			
			
			

					select @m_itemcode=t1.U_ItemCode
					,@m_doctype=t0.U_PrType
					,@m_cc=t0.U_Cccode 
					,@m_prjcode=t0.U_Project
					,@m_qty=t1.U_ReqQTY
					,@m_code=t1.LineId
					,@m_PRInvUoM=t1.U_UOM
					,@m_reqdate =t1.U_ReqDate
					,@m_docdate=t0.U_CRDate 
					from [@ZMPRD] t0 inner join [@ZMPR1] t1
					on t0.DocEntry=t1.docentry inner join oitm t3
					on t1.U_ItemCode=t3.ItemCode
					where t0.docentry=@m_docentry
					and t1.LineId=@m_currline

					select @m_ItmsGrpCod=ItmsGrpCod 
					from oitm 
					where itemcode=@m_itemcode

					-----------------------------------------------------------------
					/*
					Coding ID:PRR_001
					By:Will
					Date:20131204
					description: Direct item should not assign any cost center or project
					Remark:Coding
					*/
					-----------------------------------------------------------------	
					if @m_ItmsGrpCod in ('104','105','106') and (@m_cc is not null or @m_prjcode is not null)
					begin
							set @error=1
							set @error_message='(PRR_001)No cost center/project can be assigned to direct item '+@m_itemcode+'.'
							select @error,@error_message 
							
					end

					-----------------------------------------------------------------
					/*
					Coding ID:PRR_002
					By:Will
					Date:20131204
					description: Chemical or Expense item only assign cost center.
					Remark:Coding
					*/
					-----------------------------------------------------------------				
					if @m_ItmsGrpCod in ('110','101') and @m_cc is null
					begin
							set @error=1
							set @error_message='(PRR_002)Cost center must be assigned to chemical item '+@m_itemcode+'.'
							select @error,@error_message 
							
					
					end
					if @m_ItmsGrpCod in ('110','101') and @m_prjcode is not null
					begin
							set @error=1
							set @error_message='(PRR_002)Cost center must be assigned to chemical item '+@m_itemcode+'.'
							select @error,@error_message 
							
					end

					-----------------------------------------------------------------
					/*
					Coding ID:PRR_003
					By:Will
					Date:20131204
					description: Tooling,Gage,Fixture item is only assign project or cost center
					Remark:Coding
					*/
					-----------------------------------------------------------------
					if @m_ItmsGrpCod in ('102','103','107') and @m_prjcode is not null and @m_cc is not null
					begin
							set @error=1
							set @error_message='(PRR_003)Cost center/project must be assigned to item '+@m_itemcode+'.'
							select @error,@error_message 
							return
					end
					if @m_ItmsGrpCod in ('102','103','107') and @m_prjcode is null and @m_cc is null
					begin
							set @error=1
							set @error_message='(PRR_003)Cost center/project must be assigned to item '+@m_itemcode+'.'
							select @error,@error_message 

					end

					-----------------------------------------------------------------
					/*
					Coding ID:PRR_004
					By:Will
					Date:20131204
					description: the capital item should be assigned to a capital project, but DON'T assign to any cost center
					Remark:Coding
					*/
					-----------------------------------------------------------------	
					if @m_ItmsGrpCod in ('108') and @m_cc is not null
					begin
							set @error=1
							set @error_message='(PRR_004)Project code must be assigned to capital item '+@m_itemcode+'.'
							select @error,@error_message 

					end
					if @m_ItmsGrpCod in ('108') and @m_prjcode is null
					begin
							set @error=1
							set @error_message='(PRR_004)Project code must be assigned to capital item '+@m_itemcode+'.'
							select @error,@error_message 

					end

					-----------------------------------------------------------------
					/*
					Coding ID:PRR_005
					By:Will
					Date:20131204
					description: the indirect PR only contain indirect item.
					Remark:Coding
					*/
					-----------------------------------------------------------------
					if @m_doctype='I' and @m_ItmsGrpCod in ('104','105','106')
					begin
							set @error=1
							set @error_message='(PRR_005)The item '+@m_itemcode+' cannot be requested in Indirect PR.'
							select @error,@error_message 

					end

					-----------------------------------------------------------------
					/*
					Coding ID:PRR_006
					By:Will
					Date:20131204
					description: the Direct PR only contain direct item.
					Remark:Coding
					*/
					-----------------------------------------------------------------
					if @m_doctype='D' and @m_ItmsGrpCod not in ('104','105','106')
					begin
							set @error=1
							set @error_message='(PRR_006)The item '+@m_itemcode+' cannot be requested in Direct PR.'
							select @error,@error_message 

					end

					-----------------------------------------------------------------
					/*
					Coding ID:PRR_007
					By:Will
					Date:20131204
					description: MM confirmation validation
					Remark:Coding
					*/
					-----------------------------------------------------------------
					set @m_rows=0
					select @m_rows=COUNT(*)
					from OITM t0 inner join OITB t1
					on t0.ItmsGrpCod =t1.ItmsGrpCod
					where t0.itemcode=@m_itemcode
					and t1.U_m_mm='Y'
					and t0.U_m_mm='N'
					if @m_rows>0
					begin
							set @error=1
							set @error_message='(PRR_007)The item '+@m_itemcode+' has not got confirmation from MM in item master as required.'
							select @error,@error_message 

					end

					
					
					-----------------------------------------------------------------
					/*
					Coding ID:PRR_010
					By:Will
					Date:20131204
					description: Order multiple Quantity validation
					Remark:Coding
					*/
					-----------------------------------------------------------------
					set @m_rows=0
					select @m_rows=COUNT(*)
					from OITM t0 
					where t0.itemcode=@m_itemcode
					and t0.InvntItem='Y'
					and @m_qty % (case when isnull(t0.OrdrMulti,0)=0 then 1 else t0.OrdrMulti end)<>0
					
					if @m_rows>0
					begin
							select @m_pqty=t0.OrdrMulti
							from OITM t0 
							where t0.itemcode=@m_itemcode
							and t0.InvntItem='Y'
							and @m_qty % (case when t0.OrdrMulti=0 then 1 else t0.OrdrMulti end)<>0 
							set @error=1
							set @error_message='(PRR_010)PR quantity of item '+@m_itemcode+' must be integral multiple of order multiple quantity '+convert(varchar(20),@m_pqty)+' defined in item master. Please specify original request quantity in free text by line for reference.'
							select @error,@error_message 

					end

					-----------------------------------------------------------------
					/*
					Coding ID:PRR_011
					By:Will
					Date:20131204
					description: min.Order Quantity validation
					Remark:Coding
					*/
					-----------------------------------------------------------------
					set @m_rows=0
					select @m_rows=COUNT(*)
					from OITM t0 
					where t0.itemcode=@m_itemcode
					and t0.InvntItem='Y'
					and t0.MinOrdrQty>@m_qty
					and isnull(t0.MinOrdrQty,0)>0
					if @m_rows>0
					begin
							select @m_pqty=t0.MinOrdrQty
							from OITM t0 
							where t0.itemcode=@m_itemcode
							and t0.InvntItem='Y'
							and t0.MinOrdrQty>@m_qty
							and isnull(t0.MinOrdrQty,0)>0 
							set @error=1
							set @error_message='(PRR_011)PR quantity of item '+@m_itemcode+' must be greater than the min. order quantity '+convert(varchar(20),@m_pqty)+' defined in item master. Please specify original request quantity in free text by line for reference'
							select @error,@error_message 

					end

					-----------------------------------------------------------------
					/*
					Coding ID:PRR_012
					By:Will
					Date:20131204
					description: the UoM in PR line must the same as Inv.UoM in Item master date
					Remark:Coding
					*/
					-----------------------------------------------------------------
					
					if @m_reqdate<=@m_docdate 
					begin
							set @error=1
							set @error_message='(PRR_013)The requirement date of item '+@m_itemcode+' must be later than PR creation date.'
							select @error,@error_message 

					end 

					set @m_rows=0
					select @m_rows=count(*)
					from [@ZMPRD] t0 inner join [@ZMPR1] t1
					on t0.docentry=t1.docentry inner join oitm t2
					on t1.U_ItemCode=t2.ItemCode
					where t1.U_ItemCode=@m_itemcode 
					and t0.DocEntry=@list_of_cols_val_tab_del
					and ISNULL(t1.U_UOM,'')=''          /*Vince,2014/02/24,t1.U_UOM is null ->ISNULL(t1.U_UOM,'')=''*/
					and t2.InvntItem='Y'
					if @m_rows>0
					begin
							set @error=1
							set @error_message='(PRR_014A)Please enter the UoM of line '+convert(varchar(20),@m_currline)+'.'  /*Vince,2014/02/24,@m_currline+1->@m_currline */
							select @error,@error_message 

					end
					
					set @m_rows=0
					select @m_rows=count(*)
					from [@ZMPRD] t0 inner join [@ZMPR1] t1
					on t0.docentry=t1.docentry inner join oitm t2
					on t1.U_ItemCode=t2.ItemCode
					where t1.U_ItemCode=@m_itemcode 
					and t0.DocEntry=@list_of_cols_val_tab_del
					and t1.U_UOM<>t2.InvntryUom  
					and t2.InvntItem='Y'
					and T1.LineID=@m_currline   /*Vince, 20140226, add new condition*/
					if @m_rows>0
					begin
							select @m_InvUoM=t0.InvntryUom
							from OITM t0 
							where t0.itemcode=@m_itemcode
							set @error=1
							set @error_message='(PRR_014B)The UoM of line '+convert(varchar(20),@m_currline)+' must be '+@m_InvUoM+' as defined in item master inventory UoM.'
							select @error,@error_message 

					end 

					set @m_rows=0
					select @m_rows=count(*)
					from [@ZMPRD] t0 inner join [@ZMPR1] t1
					on t0.docentry=t1.docentry inner join oitm t2
					on t1.U_ItemCode=t2.ItemCode
					where t1.U_ItemCode=@m_itemcode 
					and t0.DocEntry=@list_of_cols_val_tab_del
					and ISNULL(t1.U_UOM,'')=''   /*Vince, 20140226, is not null-> isnull*/
					and t2.InvntItem='N'
					and T1.LineID=@m_currline   /*Vince, 20140226, add new condition*/
					if @m_rows>0
					begin
							set @error=1
							set @error_message='(PRR_015) Please enter the UoM of line '+convert(varchar(20),@m_currline)+'.'  /*Vince, 20140226, Delete +1 */
							select @error,@error_message 

					end 

				
		
				FETCH NEXT FROM UC INTO @m_docentry,@m_itemcode,@m_currline
				END

				CLOSE UC
				DEALLOCATE UC




			-----------------------------------------------------------------
			/*
			Coding ID:PR_001
			By:Will
			Date:20131204
			description: check valid Cost center
			Remark:Coding
			*/
			-----------------------------------------------------------------		
			 set @m_rows=0
			 select @m_rows=count(*)
			 from [@ZMPRD] t0 inner join [@ZMPR1] t1
			 on t0.DocEntry=t1.docentry 
			 where t0.docentry=@list_of_cols_val_tab_del
			 and t0.U_Cccode is not null

			 if @m_rows>0
			 begin
					select @m_cc=t0.U_Cccode
					from [@ZMPRD] t0 
					where t0.docentry=@list_of_cols_val_tab_del
			        
					set @m_rows=0
					select @m_rows=count(*)
					from oprc 
					where oprc.PrcCode=@m_cc

					if @m_rows=0
					begin
							set @error=1
							set @error_message='(PR_001)The Cost Center is not a valid one'
							select @error,@error_message 
							return
					end
			End  /*Vince, 20140311,Add End*/

			 -----------------------------------------------------------------
			/*
			Coding ID:PR_002
			By:Will
			Date:20131204
			description: check valid Project
			Remark:Coding
			*/
			-----------------------------------------------------------------		
			 set @m_rows=0
			 select @m_rows=count(*)
			 from [@ZMPRD] t0 inner join [@ZMPR1] t1
			 on t0.DocEntry=t1.docentry 
			 where t0.docentry=@list_of_cols_val_tab_del
			 and t0.U_Project is not null

			 if @m_rows>0
			 begin
					select @m_prjcode=t0.U_Project 
					,@m_docdate=t0.U_DocDate 
					from [@ZMPRD] t0 
					where t0.docentry=@list_of_cols_val_tab_del
			        
					set @m_rows=0
					select @m_rows=count(*)
					from oprj 
					where oprj.PrjCode=@m_prjcode
			
					if @m_rows=0
					begin
							set @error=1
							set @error_message='(PR_002)The project is not valid on PR document date.'
							select @error,@error_message 
							return
					end
					else
					begin
							set @m_rows=0
							select @m_rows=count(*)
							from oprj 
							where oprj.PrjCode=@m_prjcode
							and oprj.ValidFrom<=@m_docdate 
							and isnull(oprj.ValidTo,'20991231')>=@m_docdate
							if @m_rows=0
							begin
									set @error=1
									set @error_message='(PR_002)The doc. Date is over the project period.'
									select @error,@error_message 
									return
							end 
					end
			 end

			-------------------------------------------------------------------
			/*
			Coding ID:PR_003
			By:Will
			Date:20131104
			description: Cost center owner can NOT create own PR
			Remark:Coding
			*/
			-------------------------------------------------------------------	
			set @m_rows=0
			select @m_rows=COUNT(*)
			from [@ZMPRD] t0 inner join [@ZMPR1] t1
			on t0.docentry=t1.docentry inner join OPRC t2
			on t0.U_Cccode=t2.PrcCode inner join OUSR t3
			on t0.UserSign =t3.USERID
			where t3.USER_CODE=t2.U_owner
			and t0.U_Cccode is not null
			and t0.DocEntry=@list_of_cols_val_tab_del
			if @m_rows>0
			begin
				set @error=1
				set @error_message='(PR_003)Cost center owner is not allowed to create PR for own cost center.'
				select @error,@error_message 
									return
			end

			-------------------------------------------------------------------
			/*
			Coding ID:PR_004
			By:Will
			Date:20131104
			description: Project owner can NOT create own PR
			Remark:Coding
			*/
			-------------------------------------------------------------------	
			set @m_rows=0
			select @m_rows=COUNT(*)
			from [@ZMPRD] t0 inner join [@ZMPR1] t1
			on t0.docentry=t1.docentry inner join oprj t2
			on t0.U_Project=t2.PrjCode inner join OUSR t3
			on t0.UserSign =t3.USERID
			where t3.USER_CODE=t2.U_owner
			and t0.U_Project is not null
			and t0.DocEntry=@list_of_cols_val_tab_del
			if @m_rows>0
			begin
				set @error=1
				set @error_message='(PR_004)Project owner is not allowed to create PO for own project.'
				select @error,@error_message 
									return
			end

			-------------------------------------------------------------------
			/*
			Coding ID:PR_005
			By:Will
			Date:20131104
			description: Creator validation for manager
			Remark:Coding
			*/
			-------------------------------------------------------------------	
			set @m_rows=0
			select @m_rows=COUNT(*)
			from [@ZMPRD] t0 inner join [@ZMPR1] t1
			on t0.docentry=t1.docentry inner join OUSR t3
			on t0.UserSign =t3.USERID
			where t0.DocEntry=@list_of_cols_val_tab_del
			and t3.U_m_role in ('GM','MM','FM')
			if @m_rows>0
			begin
				set @error=1
				set @error_message='(PR_005)You have no right to create PR. Please check role assignment in user master.'
				select @error,@error_message 
				return
			end

			-------------------------------------------------------------------
			/*
			Coding ID:PR_006
			By:Will
			Date:20140110
			description: set frozen indicator value as 'No' for PR line which is not referenced
			Remark:Coding
			*/
			-------------------------------------------------------------------	
			update [@ZMPR1]
			set U_Frozen='N'
			where DocEntry=@list_of_cols_val_tab_del
			      AND U_Frozen<>'Y'

	--End /*Vince, 20140311,cancel End*/

			-----------------------------------------------------------------
			/*
			Coding ID:PRR_007
			By:Vince
			Date:20140421
			description: Check whether the project or cost center is valid.
			Remark:Coding
			*/
			-----------------------------------------------------------------	
			IF (SELECT active FROM OPRJ WHERE prjcode=(SELECT U_Project FROM [@ZMPRD] WHERE docentry=@list_of_cols_val_tab_del) )='N'
				AND (SELECT ISNULL(U_Project,'') FROM [@ZMPRD] WHERE docentry=@list_of_cols_val_tab_del)<>''
			BEGIN
				set @error=1
				set @error_message='(PRR_007_01)Project is inactive!'
			END


			IF ((SELECT u_docdate FROM [@ZMPRD] WHERE docentry=@list_of_cols_val_tab_del)<
					(SELECT ISNULL(ValidFrom,'1900.01.01') FROM OPRJ WHERE prjcode=(SELECT U_Project FROM [@ZMPRD] WHERE docentry=@list_of_cols_val_tab_del) )
				OR (SELECT u_docdate FROM [@ZMPRD] WHERE docentry=@list_of_cols_val_tab_del)>
					(SELECT ISNULL(ValidTo,'2900.01.01') FROM OPRJ WHERE prjcode=(SELECT U_Project FROM [@ZMPRD] WHERE docentry=@list_of_cols_val_tab_del) ))
				AND (SELECT ISNULL(U_Project,'') FROM [@ZMPRD] WHERE docentry=@list_of_cols_val_tab_del)<>''
			BEGIN
				set @error=1
				set @error_message='(PRR_007_02)Project is inactive!'
			END


			IF (SELECT active FROM oprc WHERE prccode=(SELECT U_Cccode FROM [@ZMPRD] WHERE docentry=@list_of_cols_val_tab_del) )='N'
				AND (SELECT ISNULL(U_Cccode,'') FROM [@ZMPRD] WHERE docentry=@list_of_cols_val_tab_del)<>''
			BEGIN
				set @error=1
				set @error_message='(PRR_007_03)Cost Center is inactive!'
			END


			IF ((SELECT u_docdate FROM [@ZMPRD] WHERE docentry=@list_of_cols_val_tab_del)<
					(SELECT ISNULL(ValidFrom,'1900.01.01') FROM oprc WHERE prccode=(SELECT U_Cccode FROM [@ZMPRD] WHERE docentry=@list_of_cols_val_tab_del) )
				OR (SELECT u_docdate FROM [@ZMPRD] WHERE docentry=@list_of_cols_val_tab_del)>
					(SELECT ISNULL(ValidTo,'2900.01.01') FROM oprc WHERE prccode=(SELECT U_Cccode FROM [@ZMPRD] WHERE docentry=@list_of_cols_val_tab_del) ))
				AND (SELECT ISNULL(U_Cccode,'') FROM [@ZMPRD] WHERE docentry=@list_of_cols_val_tab_del)<>''
			BEGIN
				set @error=1
				set @error_message='(PRR_007_04)Cost Center is inactive!'
			END


			-------------------------------------------------------------------
			/*
			   Coding ID:PR_009
			   By:Vince
			   Date:20140430
			   description: Cannot modify PR when approval
			   Remark:Coding
			*/
			-------------------------------------------------------------------	

			IF ((SELECT count(*) FROM [@ZMPRD] T0 INNER JOIN [@ZMPR1] T1 ON T0.DocEntry=T1.DocEntry 
				WHERE T0.DocEntry=@list_of_cols_val_tab_del)
				<>
				(SELECT count(*) FROM [@AZMPRD] T0 INNER JOIN [@AZMPR1] T1 ON T0.DocEntry=T1.DocEntry and T0.LogInst=T1.LogInst
				WHERE T0.DocEntry=@list_of_cols_val_tab_del 
				AND T0.LogInst=(SELECT MAX(LogInst) FROM [@AZMPRD] WHERE DocEntry=@list_of_cols_val_tab_del))
				AND 
				(SELECT T0.U_Submit FROM [@ZMPRD] T0 WHERE T0.DocEntry=@list_of_cols_val_tab_del)='Y')
				OR
				(SELECT count(*) FROM [@ZMPRD] T0 INNER JOIN [@ZMPR1] T1 ON T0.DocEntry=T1.DocEntry 
				WHERE T0.DocEntry=@list_of_cols_val_tab_del)<=0
			BEGIN
					set @error=1
					set @error_message='(PR_009) Cannot modify PR!'
			END




End

if (@object_type='PR') and (@transaction_type in ('U'))
Begin
		-------------------------------------------------------------------
		/*
		   Coding ID:PR_006
		   By:Will
		   Date:20131104
		   description: when the modificator is not a approver, the document approval status will be change to un-approval
		   Remark:Coding
		   20131106:Because the PR is user-defined object. it's no usersign2 to record editor user id. So we get editor user id 
		            from AZMPRD - PR log table.
		*/
		-------------------------------------------------------------------	
  		set @m_rows=0
		select @m_rows=count(*) 
		from [@AZMPRD] t0 inner join  ousr t2
		on t0.usersign=t2.USERID
		where docentry=@list_of_cols_val_tab_del
		and loginst=(select max(loginst) from [@AZMPRD] where docentry=@list_of_cols_val_tab_del)
		and t2.USER_CODE not in(
								select distinct tt1.Candidate
								from OWLS tt0 inner join WLS1 tt1
								on tt0.WFInstID =tt1.WFInstID 
								and tt0.TaskID=tt1.TaskID
								inner join WLS2 tt2
								on tt0.WFInstID =tt2.WFInstID 
								and tt0.TaskID =tt2.TaskID
								where tt2.ObjectType=@object_type
								and tt2.ObjKey=@list_of_cols_val_tab_del 
								and (tt1.Candidate<>'workflow')
		)

		if @m_rows>0
		begin
			-------------------------------------------------------------------
			/*
			Coding ID:PR_006_01
			By:Will
			Date:20131213
			description: when PR was be updated, only the doc.total is over related amount, the approval indicators will be updated.
			Remark:Coding
			*/
			-------------------------------------------------------------------
			set @m_rows=0
			select @m_rows=count(*)
			from [@ZMPRD] t0 inner join [@ZMPR1] t1
			on t0.docentry=t1.docentry 
			left outer join ousr t2
			on t0.U_Usersign2=t2.USERID 
			where t0.docentry=@list_of_cols_val_tab_del
			/*Vince, 20140422*/
			--and t0.u_UserSign=isnull(t0.U_Usersign2,t0.u_UserSign)
			and t0.u_submit='Y'

			if @m_rows>0 
			begin
						set @error=1
						set @error_message='(PR_007A)The document in approval process cannot be updated.'
						select @error,@error_message 
						return
			end

			set @m_rows=0
			select @m_rows=count(*)
			from [@ZMPRD] t0 inner join [@ZMPR1] t1
			on t0.docentry=t1.docentry 
			left outer join ousr t2
			on t0.U_Usersign2=t2.USERID 
			where t0.docentry=@list_of_cols_val_tab_del
			and t0.u_UserSign<>T0.U_Usersign2
			/*Vince,20140422*/
			--and isnull(t2.U_m_role,'NO')<>('AD')
			and t2.SUPERUSER='N'
			--and t0.u_submit='N'
			if @m_rows>0 
			begin
						set @error=1
						set @error_message='(PR_007B)Only PR creator and system administrator can modify this PR.'
						select @error,@error_message 
						return
			end

			update [@ZMPRD] 
			set U_Confirmed='N'
			,U_approval='0'
			from [@ZMPRD] t0 inner join [@ZMPR1] t1
			on t0.docentry=t1.docentry left outer join 
			[@azmprd] t2 inner join [@azmpr1] t3
			on t2.DocEntry=t3.DocEntry 
			and t2.LogInst=t3.LogInst
			and t2.Object=t3.Object
			on t0.Object =t2.Object 
			and t0.DocEntry =t2.DocEntry 
			and t2.LogInst =(
									select MAX(LogInst)-1
									from [@azmprd]
									where DocEntry=t0.DocEntry
									and object=t0.Object
								)
			and t1.LineId=t3.LineId 
			where t0.docentry=@list_of_cols_val_tab_del
			and (t1.U_Price<>isnull(t3.u_Price,0) 
			or t0.U_Cccode<>isnull(t2.U_Cccode,0)
			or t0.u_Project<>isnull(t2.u_Project,0)
			or t1.U_ReqQTY<>isnull(t3.U_ReqQTY,0)
			or t1.U_Currency<>isnull(t3.U_Currency,0)
			or t0.U_Doctotal<>isnull(t2.U_Doctotal,0))
			
			-------------------------------------------------------------------
			/*
			Coding ID:Pr_006_02
			By:Vince
			Date:20140228
			description: When the document is updated and the document is rejected, the approval indicators will be updated.
			Remark:Coding
			*/
			-------------------------------------------------------------------	
			update [@ZMPRD] 
			set U_Confirmed='N'
			,U_approval='0'
			from [@ZMPRD] t0 inner join [@ZMPR1] t1
			on t0.docentry=t1.docentry left outer join 
			[@azmprd] t2 inner join [@azmpr1] t3
			on t2.DocEntry=t3.DocEntry 
			and t2.LogInst=t3.LogInst
			and t2.Object=t3.Object
			on t0.Object =t2.Object 
			and t0.DocEntry =t2.DocEntry 
			and t2.LogInst =(
									select MAX(LogInst)-1
									from [@azmprd]
									where DocEntry=t0.DocEntry
									and object=t0.Object
								)
			and t1.LineId=t3.LineId 
			where t0.docentry=@list_of_cols_val_tab_del
			and t2.U_approval=1

		end

		




End

if (@object_type='PR') and (@transaction_type in ('D'))
Begin
		set @error=1
		set @error_message='(PR_003)Purchase request is not allowed to delete. Please try to close PR line.'
		select @error,@error_message 
End

/***********************************************************************
*****************************Purchase Order*****************************
***********************************************************************
    The below source code is for update quantity and avalible amount on PR 
	line according when PO lines was modifications.
	the related code id is PO2PR_001;PO2PR_002;PO2PR_004;PO2PR_005;
************************************************************************/
if (@object_type = '22') and (@transaction_type in ('A','U'))
Begin
		DECLARE UC CURSOR FOR
			SELECT t0.docentry
			,t1.itemcode
			,t1.linenum
			from opor t0 inner join por1 t1
			on t0.docentry=t1.docentry
			where t0.docentry=@list_of_cols_val_tab_del 
			OPEN UC
			FETCH NEXT FROM UC INTO @m_docentry,@m_itemcode,@m_currline
			WHILE @@FETCH_STATUS=0
			BEGIN
							-------------------------------------------------------------------
							/*
							Coding ID:POR_001
							By:Will
							Date:20131129
							description: get Original price and price source 
							Remark:Coding
							*/
							-------------------------------------------------------------------	
							
							/*get the filter parameters from current PO*/
							select @m_cardcode=t0.cardcode
							,@m_itemcode=t1.itemcode
							,@m_reqQTY=t1.InvQty
							,@m_postdate=t0.DocDate
							,@m_currency=t1.Currency
							,@m_unitprice=t1.Price
							,@m_agentry=t1.agrno
							,@m_agline=t1.agrlnnum
							from opor t0 inner join por1 t1
							on t0.docentry=t1.docentry
							where t0.DocEntry=@list_of_cols_val_tab_del
							and t1.LineNum=@m_currline
							/*end get filter..*/

							/*get price and currency from specail price for BP*/
							set @m_rows=0
							select @m_rows=count(*)
							from ospp t0
							left outer join
							(	
								/*get price and currency from period stage*/
								select tt0.ItemCode
								,tt0.CardCode
								,tt0.price price01
								,tt0.Currency currency01
								,tt1.price price02
								,tt1.Currency currency02
								from spp1 tt0
								left outer join 
								(	
				
									select ps.ItemCode
									,ps.CardCode
									,ps.Currency 
									,min(ps.price) price
									from
									(		
													/*get Price and Currency from quantity stage*/
													select *
													from spp2 ttt0
													where ttt0.ItemCode=@m_itemcode
													and ttt0.CardCode=@m_cardcode
													and ttt0.Amount<=@m_reqQTY
													/*end get price from quantity stage*/
									)ps
									group by ps.CardCode 
									,ps.ItemCode
									,ps.Currency 
								) tt1
								on tt0.ItemCode =tt1.ItemCode 
								and tt0.CardCode =tt1.CardCode
								where tt0.ItemCode=@m_itemcode
								and tt0.CardCode=@m_cardcode
								and tt0.FromDate<=@m_postdate
								and tt0.todate>=@m_postdate
								/*end get price from period stage*/
								) t1
							on t0.ItemCode =t1.ItemCode
							and t0.CardCode=t1.CardCode 
							where t0.ItemCode=@m_itemcode
							and t0.CardCode=@m_cardcode
							/*end get price from special price from BP*/
							if @m_rows>0
							begin


										/*get price and currency from specail price for BP*/
										select @m_orinprice=case when isnull(t1.price02,0)=0 then (case when isnull(t1.price01,0)=0 then t0.price else t1.price01 end) else  t1.price02 end 
										,@m_orincurrency=case when isnull(t1.price02,0)=0 then (case when isnull(t1.price01,0)=0 then t0.Currency else t1.currency01 end) else  t1.currency02 end 
										from ospp t0
										left outer join
										(	
											/*get price and currency from period stage*/
											select tt0.ItemCode
											,tt0.CardCode
											,tt0.price price01
											,tt0.Currency currency01
											,tt1.price price02
											,tt1.Currency currency02
											from spp1 tt0
											left outer join 
											(	
				
												select ps.ItemCode
												,ps.CardCode
												,ps.Currency 
												,min(ps.price) price
												from
												(		
																/*get Price and Currency from quantity stage*/
																select *
																from spp2 ttt0
																where ttt0.ItemCode=@m_itemcode
																and ttt0.CardCode=@m_cardcode
																and ttt0.Amount<=@m_reqQTY
																/*end get price from quantity stage*/
												)ps
												group by ps.CardCode 
												,ps.ItemCode
												,ps.Currency 
											) tt1
											on tt0.ItemCode =tt1.ItemCode 
											and tt0.CardCode =tt1.CardCode
											where tt0.ItemCode=@m_itemcode
											and tt0.CardCode=@m_cardcode
											and tt0.FromDate<=@m_postdate
											and tt0.todate>=@m_postdate
											/*end get price from period stage*/
											) t1
										on t0.ItemCode =t1.ItemCode
										and t0.CardCode=t1.CardCode 
										where t0.ItemCode=@m_itemcode
										and t0.CardCode=@m_cardcode
										/*end get price from special price from BP*/

										update POR1 
										set por1.u_m_price=@m_orinprice*t2.NumInBuy
										,por1.u_m_prcsr='Y'
										,por1.u_m_currency=@m_orincurrency
										from por1 t1 inner join oitm t2
										on t1.ItemCode=t2.ItemCode 
										where t1.ItemCode=@m_itemcode
										and t1.DocEntry=@list_of_cols_val_tab_del
										and t1.LineNum =@m_currline
							end
							else
							begin
									select @m_orinprice=isnull(t0.price,0)
									,@m_orincurrency=t0.currency
									from ITM1 t0 inner join OCRD t1
									on t0.PriceList=t1.ListNum
									where t1.CardCode=@m_cardcode 
									and t0.ItemCode=@m_itemcode
									if @m_orinprice>0 and @m_orincurrency is not null
									begin/*Price list*/
									   update POR1 
									   set por1.u_m_price=@m_orinprice*t2.NumInBuy
										  ,por1.u_m_prcsr='R'
										  ,por1.u_m_currency=@m_orincurrency
									   from por1 t1 inner join oitm t2
										on t1.ItemCode=t2.ItemCode 
										where t1.ItemCode=@m_itemcode
										and t1.DocEntry=@list_of_cols_val_tab_del
										and t1.LineNum =@m_currline
									end/*Price list*/
									else
									begin/*manual*/
									   update POR1 
									   set por1.u_m_price=@m_unitprice
										  ,por1.u_m_prcsr='N'
										  ,por1.u_m_currency=@m_currency
									   where ItemCode=@m_itemcode
									   and DocEntry=@list_of_cols_val_tab_del
									   and LineNum =@m_currline
									end/*manual*/
							end/*end for price list and manual*/
							-------------------------------------------------------------------
							/*
							End PO_001
							*/
							-------------------------------------------------------------------

							-------------------------------------------------------------------
							/*
							Coding ID:POR_002
							By:Will
							Date:20131129
							description: Purchase quantirty cannot over the Blanket Agreement Planning quantity
							Remark:Coding
							*/
							-------------------------------------------------------------------

							if @m_agentry is not null
							begin

									/*get the historical PO open inv.QTY*/
									
									/*Vince,201400326,update,only calculate from open PO*/
									select @m_hisqty=sum(ISNULL(t1.InvQty,0))
									from opor t0 inner join por1 t1
									on t0.DocEntry=t1.DocEntry  
									where t0.CardCode=@m_cardcode
									and t1.ItemCode=@m_itemcode
									and t1.LineStatus='O'
									and t1.AgrNo=@m_agentry 
									and t1.AgrLnNum=@m_agline

									/*Vince,201400326,add,only calculate received qty from closed PO*/
									select @m_hisqty=@m_hisqty+sum(isnull(t1.InvQty,0))-sum(isnull(t3.InvQty,0))
									from opdn t0 
									inner join pdn1 t1 on t0.DocEntry=t1.DocEntry 
									left join por1 t2 on t2.DocEntry=t1.BaseEntry and t2.LineNum =t1.BaseLine
									left join rpd1 t3 on t3.BaseEntry =t1.DocEntry  and t3.BaseLine =t1.LineNum
									where t0.CardCode=@m_cardcode
									and t1.ItemCode=@m_itemcode
									and t1.AgrNo=@m_agentry 
									and t1.AgrLnNum=@m_agline
									and t1.BaseType =22
									and t2.LineStatus ='C'
									and t0.CANCELED='N'  /*Vince,20140422*/

									select @m_pqty=t1.PlanQty+case when isnull(t1.freetxt,'')='' then 0 else t1.freetxt end
									from OOAT t0 inner join OAT1 t1
									on t0.AbsID =t1.AgrNo
									where t0.Cancelled<>'Y' 
									and t0.Status<>'T'
									and t0.BpCode=@m_cardcode
									and t1.ItemCode=@m_itemcode
									and t0.AbsID=@m_agentry 
									and t1.AgrLineNum=@m_agline

									if (@m_pqty-@m_hisqty)<0 
									begin
										set @error=1
										set @error_message='(POR_002)Cumulated purchase quantity of '+convert(varchar(10),@m_currline)+@m_itemcode+' is over than linked blanket agreement plan quantity, the plan quantity of agreement is '+CONVERT(varchar(20),@m_pqty)+' and the avaialbe quantity is '+CONVERT(varchar(20),@m_pqty-(@m_hisqty-@m_reqQTY) )
										select @error,@error_message 
										

									end
							end


							-------------------------------------------------------------------
							/*
							Coding ID:POR_005
							By:Will
							Date:20131104
							description: the MM check indicators validations
							Remark:Coding
							*/
							-------------------------------------------------------------------	
							set @m_rows=0
							select @m_rows=count(*)
							from oitm t1 inner join oitb t2
							on t1.ItmsGrpCod=t2.ItmsGrpCod 
							where t1.U_m_mm='N'
							and t2.u_m_mm='Y'
							and t1.itemcode=@m_itemcode

							if @m_rows>0
							begin
								set @error=1
								set @error_message='(POR_005)The line:'+convert(varchar(10),@m_currline)+' :'+@m_itemcode+'-'+' has not got confirmation from MM in item master as required.'
								select @error,@error_message 
								
							end
							
							-------------------------------------------------------------------
							/*
							Coding ID:POR_006
							By:Will
							Date:20131104
							description: The purchasing QTY must great than min.Ordr.QTY when need check minOrderQTY
							Remark:Coding
							*/
							-------------------------------------------------------------------	
							set @m_rows=0
							select @m_rows=count(*)
							from opor t0 inner join por1 t1
							on t0.docentry=t1.docentry inner join oitm t2
							on t1.ItemCode=t2.ItemCode 
							where t0.docentry=@list_of_cols_val_tab_del
							and t1.LineNum=@m_currline
							and t2.InvntItem='Y'
							and t1.U_m_MinQtychk='Y'
							and t1.InvQty<t2.MinOrdrQty
							and isnull(t2.MinOrdrQty,0)>0
							if @m_rows>0
							begin
								set @error=1
								set @error_message='(POR_006)The PO quantity of line:'+convert(varchar(10),@m_currline)+' :'+@m_itemcode+'-'+' is lower than min. order quantity defined in item master.'
								select @error,@error_message 
								
							end

							-------------------------------------------------------------------
							/*
							Coding ID:POR_007
							By:Will
							Date:20131104
							description: The purchasing QTY must great than mutiple Ordr.QTY when need check multipleQTY
							Remark:Coding
							*/
							-------------------------------------------------------------------	
							set @m_rows=0
							select @m_rows=count(*)
							from opor t0 inner join por1 t1
							on t0.docentry=t1.docentry inner join oitm t2
							on t1.ItemCode=t2.ItemCode 
							where t0.docentry=@list_of_cols_val_tab_del
							and t1.LineNum=@m_currline
							and t2.InvntItem='Y'
							and t1.U_m_multiOrQtychk='Y'
							and isnull(t2.OrdrMulti,0)>0
							and (t1.InvQty<t2.OrdrMulti or (t1.InvQty % case when isnull(t2.OrdrMulti,0)=0 then 1 else t2.OrdrMulti end) <> 0)
							if @m_rows>0
							begin
								set @error=1
								set @error_message='(POR_007)The PO quantity of line:'+convert(varchar(10),@m_currline)+' :'+@m_itemcode+'-'+' does not match multiple order quantity defined in item master.'
								select @error,@error_message
							end

							-------------------------------------------------------
							/*
							Coding ID:POR_008
							By:Will
							Date:20131105
							description: the PO should based on PR when line total.
							Remark:Coding
							*/
							-------------------------------------------------------	
							set @m_rows=0
							select @m_rows=count(*)
							from opor t0 inner join por1 t1
							on t0.DocEntry=t1.DocEntry 
							where t0.DocEntry=@list_of_cols_val_tab_del
							and t1.LineTotal>0
							and t1.u_m_prid is null
							and t1.u_m_prlin is null
							and t1.LineNum=@m_currline
							if @m_rows>0
							begin
										set @error=1
										set @error_message='(POR_008)Purchase order must be created with reference to valid PR. The only exception is FOC PO.'
										select @error,@error_message
									
							end

							
							-------------------------------------------------------
							/*
							Coding ID:POR_009
							By:Will
							Date:20140110
							description: cannot procurement without source list when item is source list control
							Remark:Coding
							*/
							-------------------------------------------------------	
							set @m_rows=0
							select @m_rows=count(*)
							from opor t0 inner join por1 t1
							on t0.docentry=t1.docentry 
							inner join oitm t4
							on t1.itemcode =t4.ItemCode  
							where t0.docentry=@list_of_cols_val_tab_del
							and t4.U_m_Srclist='Y'
							and t1.LineNum=@m_currline

							if @m_rows>0
							begin

									set @m_rows=0
									select  @m_rows=count(*)
									from opor t0 inner join por1 t1
									on t0.docentry=t1.docentry inner join 
									[@ZMSLD] t2 inner join [@ZMSL1] t3
									on t2.docentry=t3.docentry
									on t1.ItemCode =t2.U_Itemcode inner join oitm t4
									on t1.ItemCode =t4.ItemCode  
									where t0.docentry=@list_of_cols_val_tab_del
									and t0.DocDate between t3.U_Validfrom and t3.U_Validto
									and t0.CardCode=t3.U_Vendorcode
									and t1.LineNum=@m_currline

									if @m_rows=0
									begin

											set @error=1
											set @error_message='(POR_009)The vendor is not defined in source list for line '+convert(varchar(20),@m_currline+1)+'.'
											select @error,@error_message 

									end
							end


							-------------------------------------------------------
							/*
							Coding ID:POR_010
							By:Will
							Date:20140116
							description: Cost center validation in PO
							Remark:Coding
							*/
							-------------------------------------------------------	
							set @m_rows=0
							select @m_rows=count(*)
							from opor t0 inner join por1 t1
							on t0.docentry=t1.docentry 
							inner join oitm t4
							on t1.itemcode =t4.ItemCode  
							where t0.docentry=@list_of_cols_val_tab_del
							and t4.ItmsGrpCod in ('110','101','102','103','107')
							and t1.OcrCode is null
							and t1.Project is not null
							and t1.LineNum=@m_currline
							if @m_rows>0
							begin

									set @error=1
									set @error_message='(POR_010)Cost center must be assigned to line '+convert(varchar(20),@m_currline+1)+'.'
									select @error,@error_message 

							end

							-------------------------------------------------------
							/*
							Coding ID:POR_011
							By:Will
							Date:20140116
							description: project validation in PO
							Remark:Coding
							*/
							-------------------------------------------------------	
							set @m_rows=0
							select @m_rows=count(*)
							from opor t0 inner join por1 t1
							on t0.docentry=t1.docentry 
							inner join oitm t4
							on t1.itemcode =t4.ItemCode  
							where t0.docentry=@list_of_cols_val_tab_del
							and t4.ItmsGrpCod in ('108')
							and t1.OcrCode is not null
							and t1.Project is null
							and t1.LineNum=@m_currline
							if @m_rows>0
							begin

									set @error=1
									set @error_message='(POR_011)Project code must be assigned to line '+convert(varchar(20),@m_currline+1)+'.'
									select @error,@error_message 

							end


							-------------------------------------------------------
							/*
							Coding ID:POR_012
							By:Will
							Date:20140116
							description: direct item has to keep cost center / project blank
							Remark:Coding
							*/
							-------------------------------------------------------	
							set @m_rows=0
							select @m_rows=count(*)
							from opor t0 inner join por1 t1
							on t0.docentry=t1.docentry 
							inner join oitm t4
							on t1.itemcode =t4.ItemCode  
							where t0.docentry=@list_of_cols_val_tab_del
							and t4.ItmsGrpCod in ('104','105','106')
							and t1.OcrCode is not null
							and t1.Project is not null
							and t1.LineNum=@m_currline

							if @m_rows>0
							begin

									set @error=1
									set @error_message='(POR_012)No cost center/project can be assigned to line '+convert(varchar(20),@m_currline+1)+'.'
									select @error,@error_message 

							end

					

				
				
				FETCH NEXT FROM UC INTO @m_docentry,@m_itemcode,@m_currline
			END

			CLOSE UC
			DEALLOCATE UC

			
			-------------------------------------------------------
			/*
			Coding ID:POR_013
			By:Vince
			Date:20140213
			description: Only one type item in one PO
			Remark:Coding
			*/
			-------------------------------------------------------	
			IF (SELECT COUNT(isnull(T0.OcrCode,''))+COUNT(isnull(T0.Project,'')) FROM POR1 T0 
					WHERE T0.DocEntry =@list_of_cols_val_tab_del
					and (isnull(T0.OcrCode,'')<>'' and isnull(T0.Project,'')<>''))   <>
				(SELECT COUNT(T0.ItemCode ) FROM POR1 T0 WHERE T0.DocEntry =@list_of_cols_val_tab_del)
				AND
				(SELECT COUNT(isnull(T0.OcrCode,''))+COUNT(isnull(T0.Project,'')) 
					FROM POR1 T0 
					WHERE T0.DocEntry =@list_of_cols_val_tab_del
					and (isnull(T0.OcrCode,'')<>'' and isnull(T0.Project,'')<>''))    <>0
			BEGIN
					set @error=1
					set @error_message='(PO_013)Combination of indirect and direct items in one PO is not allowed.'
					select @error,@error_message 
					return
			END

		


		-------------------------------------------------------------------
		/*
		Coding ID:PO_002
		By:Will
		Date:20131129
		description: the change reason should be filled when price changed.
		Remark:Coding
		*/
		-------------------------------------------------------------------
		set @m_rowcount=0
		select @m_rowcount=COUNT(*)
		from opor t0 inner join por1 t1
		on t0.DocEntry=t1.DocEntry 
		where t0.DocEntry=@list_of_cols_val_tab_del
		and t1.SpecPrice<>t1.U_m_prcsr
		and t1.u_m_Otherrsn is null
		if @m_rowcount>0
		begin
				set @error=1
				set @error_message='(PO_002)The unit price is not the original one, please choose a change reason.'
				select @error,@error_message 
				return
		end

		

		-------------------------------------------------------------------
		/*
		Coding ID:PO_005
		By:Will
		Date:20131104
		description: BP audit date was expirated.
		Remark:Coding
		*/
		-------------------------------------------------------------------
		set @m_rowcount=0
		select @m_rowcount=COUNT(*)
		from opor t0 inner join por1 t1 
		on t0.DocEntry=t1.DocEntry inner join OCRD t2
		on t0.CardCode=t2.CardCode
		where t0.DocEntry=@list_of_cols_val_tab_del
		and t2.U_m_CertfcId is not null
		and datediff(dd,t0.docdate,isnull(t2.U_m_AdtValidto,'19000101')+U_m_AdtTolrnc)<0
		and t2.u_m_exchck<>'Y'
		if @m_rowcount>0
		begin
			set @error=1
			set @error_message='(PO_005)Vendor audit is expired.'
			select @error,@error_message 
			return
		end

		-------------------------------------------------------------------
		/*
		Coding ID:PO_006
		By:Will
		Date:20131104
		description: the purchase order will be block when BP certification date was expirated.
		Remark:Coding
		*/
		-------------------------------------------------------------------
		set @m_rowcount=0
		select @m_rowcount=COUNT(*)
		from opor t0 inner join por1 t1 
		on t0.DocEntry=t1.DocEntry inner join OCRD t2
		on t0.CardCode=t2.CardCode
		where t0.DocEntry=@list_of_cols_val_tab_del
		and t2.U_m_CertfcId is not null
		--and t0.docdate>=isnull(t2.U_m_Validto,'19000101')
		and datediff(dd,t0.docdate,isnull(t2.U_m_Validto,'19000101'))<0
		and t2.u_m_exchck<>'Y'
		if @m_rowcount>0
		begin
			set @error=1
			set @error_message='(PO_006)Vendor certification is expired.'
			select @error,@error_message 
			return
		end

		-------------------------------------------------------------------
		/*
		Coding ID:PO_007
		By:Will
		Date:20131104
		description: Can't purchese item from no certificated BP
		Remark:Coding
		*/
		-------------------------------------------------------------------
		set @m_rowcount=0
		select @m_rowcount=COUNT(*)
		from opor t0 inner join por1 t1 
		on t0.DocEntry=t1.DocEntry inner join OCRD t2
		on t0.CardCode=t2.CardCode
		where t0.DocEntry=@list_of_cols_val_tab_del
        and t2.U_m_CertfcId is null
		and t2.u_m_exchck<>'Y'
		if @m_rowcount>0
		begin
			set @error=1
			set @error_message='(PO_007)Vendor certification is not valid.'
			select @error,@error_message 
			return
		end
		
		-------------------------------------------------------------------
		/*
		Coding ID:PO_008
		By:Will
		Date:20131104
		description: the purchase order will be block when the BP was be business block.
		Remark:Coding
		*/
		-------------------------------------------------------------------
		set @m_rowcount=0
		select @m_rowcount=COUNT(*)
		from opor t0 inner join por1 t1 
		on t0.DocEntry=t1.DocEntry inner join OCRD t2
		on t0.CardCode=t2.CardCode
		where t0.DocEntry=@list_of_cols_val_tab_del
		and t2.U_m_BsnssBlk='Y'

		if @m_rowcount>0
		begin
			set @error=1
			set @error_message='(PO_008)The vendor is blocked for business transactions.'
			select @error,@error_message 
			return
		end

		-------------------------------------------------------------------
		/*
		   Coding ID:PO_012
		   By:Will
		   Date:20131104
		   description: Cost center owner can NOT create own PO 
		   Remark:Coding
		*/
		-------------------------------------------------------------------	
			set @m_rows=0
			select @m_rows=COUNT(*)
			from OPOR t0 inner join por1 t1
			on t0.docentry=t1.docentry inner join OPRC t2
			on t1.OcrCode=t2.PrcCode inner join OUSR t3
			on t0.UserSign =t3.USERID
			where t3.USER_CODE=t2.U_owner
			and t1.OcrCode is not null
			and t0.DocEntry=@list_of_cols_val_tab_del
			if @m_rows>0
			begin
				  set @error=1
				  set @error_message='(PO_012)Cost center owner is not allowed to create PO for own cost center.'
				  select @error,@error_message 
			      return
			end

		-------------------------------------------------------------------
		/*
		   Coding ID:PO_013
		   By:Will
		   Date:20131104
		   description: Project owner can NOT create own PO 
		   Remark:Coding
		*/
		-------------------------------------------------------------------		
			set @m_rows=0
			select @m_rows=COUNT(*)
			from OPOR t0 inner join por1 t1
			on t0.docentry=t1.docentry inner join OPRJ t2
			on t1.OcrCode=t2.PrjCode inner join OUSR t3
			on t0.UserSign =t3.USERID
			where t3.USER_CODE=t2.U_owner
			and t1.Project is not null
			and t0.DocEntry=@list_of_cols_val_tab_del
			if @m_rows>0
			begin
				  set @error=1
				  set @error_message='(PO_013)Project owner is not allowed to create PO for own project.'
				  select @error,@error_message 
				  return
			end

			-------------------------------------------------------------------
			/*
			Coding ID:PO_014
			By:Will
			Date:20131104
			description: Creator validation for manager
			Remark:Coding
			*/
			-------------------------------------------------------------------	
			set @m_rows=0
			select @m_rows=COUNT(*)
			from opor t0 inner join por1 t1
			on t0.docentry=t1.docentry inner join OUSR t3
			on t0.UserSign =t3.USERID
			where t0.DocEntry=@list_of_cols_val_tab_del
			and t3.U_m_role in ('GM','MM','FM')
			if @m_rows>0
			begin
				set @error=1
				set @error_message='(PO_014)You have no right to create PO. Please check role assignment in user master.'
				select @error,@error_message 
				return
			end


			-------------------------------------------------------------------
			/*
			Coding ID:PO_015
			By:Will
			Date:20140116
			description: Creator validation for manager
			Remark:Coding
			*/
			-------------------------------------------------------------------	
			set @m_rows=0
			select @m_rows=COUNT(*)
			from opor t0 inner join por1 t1
			on t0.docentry=t1.docentry 
			where t0.DocEntry=@list_of_cols_val_tab_del
			and t0.SlpCode=-1
			if @m_rows>0
			begin
				set @error=1
				set @error_message='(PO_015)Buyer code is mandatory.'
				select @error,@error_message 
				return
			end




			

End

if (@object_type = '22') and (@transaction_type in ('U'))
Begin
				-------------------------------------------------------------------
				/*
				Coding ID:PO_009
				By:Will
				Date:20131104
				description: when the modificator is not a approver, the document approval status will be change to un-approval
				Remark:Coding
				*/
				-------------------------------------------------------------------	
				set @m_rows=0
				select @m_rows=COUNT(*)
				from OPOR t0 inner join POR1 t1
				on t0.DocEntry=t1.docentry inner join OUSR t2
				on t0.UserSign2=t2.USERID
				where t0.DocEntry =@list_of_cols_val_tab_del
				and t2.USER_CODE not in (
											/*get approvor */
											select distinct t1.Candidate
											from OWLS t0 inner join WLS1 t1
											on t0.WFInstID =t1.WFInstID 
											and t0.TaskID=t1.TaskID
											inner join WLS2 t2
											on t0.WFInstID =t2.WFInstID /*Vince,20140218, T1->T2*/
											and t0.TaskID =t2.TaskID /*Vince,20140218, T1->T2*/
											where t2.ObjectType=CONVERT(nvarchar(5),@object_type) /*Vince 20140218,convert*/
											and t2.ObjKey=@list_of_cols_val_tab_del 
											and t1.Candidate<>'workflow'
										)
	
				if @m_rows>0
				begin
						-------------------------------------------------------------------
						/*
						Coding ID:PO_009_01
						By:Will
						Date:20131213
						description: when PO was be updated, only the doc.total is over related amount, the approval indicators will be updated.
						Remark:Coding
						modification by:20131231 only critical field update, the approval indicator will be return
						*/
						-------------------------------------------------------------------	
						update OPOR 
						set Confirmed='N'
						,U_approval='0'
						from opor t0 inner join por1 t1
						on t0.docentry=t1.docentry left outer join 
						ADOC t2 inner join ADO1 t3
						on t2.DocEntry=t3.DocEntry 
						and t2.LogInstanc=t3.LogInstanc
						and t2.ObjType =t3.ObjType
						on t0.ObjType =t2.ObjType and t1.linenum=t3.linenum /*Vince,20140329*/
						and t0.DocEntry =t2.DocEntry 
						and t2.LogInstanc =(
												select MAX(loginstanc) 
												from ADOC
												where DocEntry=t0.DocEntry
												and objtype=t0.objtype
						                    )
						where t0.docentry=@list_of_cols_val_tab_del
						and (t1.price<>isnull(t3.Price,0) 
						or t1.Quantity<>isnull(t3.Quantity,0)
						or t1.OcrCode<>isnull(t3.OcrCode,0)
						or t1.Project<>isnull(t3.Project,0)
						or t0.DocTotal<>isnull(t2.DocTotal,0)
						or t1.Currency<>isnull(t1.Currency,0)
						or t0.U_m_ictmc<>isnull(t2.U_m_ictmc,0)
						or t0.GroupNum <>isnull(t2.GroupNum ,0)
						)


						-------------------------------------------------------------------
						/*
						Coding ID:PO_009_02
						By:Vince
						Date:20140228
						description: When the document is updated and the document is rejected, the approval indicators will be updated.
						Remark:Coding
						*/
						-------------------------------------------------------------------	
						update OPOR 
						set Confirmed='N'
						,U_approval='0'
						from opor t0 inner join por1 t1
						on t0.docentry=t1.docentry left outer join 
						ADOC t2 inner join ADO1 t3
						on t2.DocEntry=t3.DocEntry 
						and t2.LogInstanc=t3.LogInstanc
						and t2.ObjType =t3.ObjType
						on t0.ObjType =t2.ObjType 
						and t0.DocEntry =t2.DocEntry 
						and t2.LogInstanc =(
												select MAX(loginstanc) 
												from ADOC
												where DocEntry=t0.DocEntry
												and objtype=t0.objtype
						                    )
						where t0.docentry=@list_of_cols_val_tab_del
						and t2.U_approval=1



						
				end


				-----------------------------------------------------------------
				/*
				Coding ID:PO_010
				By:Will
				Date:20131104
				description: approver can not be modification limited fields.
				Remark:Coding
				*/
				-----------------------------------------------------------------		
				set @m_rows=0
				select @m_rows=COUNT(*)
				from OPOR t0 inner join POR1 t1
				on t0.DocEntry=t1.docentry inner join OUSR t2
				on t0.UserSign2=t2.USERID
				where t0.DocEntry =@list_of_cols_val_tab_del
				and t2.USER_CODE in (
										select distinct t1.Candidate
										from OWLS t0 inner join WLS1 t1
										on t0.WFInstID =t1.WFInstID 
										and t0.TaskID=t1.TaskID
										inner join WLS2 t2
										on t0.WFInstID =t1.WFInstID 
										and t0.TaskID =t1.TaskID
										where t2.ObjectType=@object_type
										and t2.ObjKey=@list_of_cols_val_tab_del 
										and t1.Candidate<>'workflow'
									)
				and t0.UserSign<>t0.UserSign2 
				if @m_rows>0
				begin
					-----------------------------------------------------------------
					/*
					Coding ID:PO_010_001
					By:Will
					Date:20131211
					description: Approver can NOT update crtitical field on PO lines
					Remark:Coding
					*/
					-----------------------------------------------------------------	
					select @m_rows2=COUNT(*)
					from ADOC t0 
					inner join ADO1 t1
					on t0.DocEntry=t1.DocEntry
					and t0.LogInstanc =t1.LogInstanc inner join 
					(OPOR t2 inner join POR1 t3 on t2.DocEntry =t3.DocEntry)
					on t0.DocEntry =t2.DocEntry
					where t0.DocEntry=@list_of_cols_val_tab_del
					and t1.objtype=@object_type and t0.objtype=@object_type    /*Vince,20140213,and t1.objtype=@object_type*/
					and t0.LogInstanc = (
											select MAX(loginstanc) 
											from ADOC
											where DocEntry=t0.DocEntry
											and objtype=t0.objtype
										)
					and t1.LineNum=t3.LineNum 
					and t2.UserSign<>t2.UserSign2 
					and (t1.Price<>t3.Price
					or t1.itemcode<>t3.itemcode
					or t1.Dscription<>t3.Dscription
					or t1.unitMsr<>t3.unitMsr
					or t1.quantity<>t3.quantity
					or t1.U_m_MinQtychk<>t3.U_m_MinQtychk
					or t1.U_m_Otherrsn<>t3.U_m_Otherrsn
					or t1.TaxCode<>t3.TaxCode
					or t1.U_m_sttcddate<>t3.U_m_sttcddate
					or t1.U_m_reqdate<>t3.U_m_reqdate
					or t1.ShipDate<>t3.ShipDate
					or t1.WhsCode<>t3.WhsCode
					or t1.Project<>t3.Project
					or t1.OcrCode<>t3.OcrCode
					or t1.SlpCode<>t3.SlpCode
					or t1.AgrNo<>t3.AgrNo
					or t1.AgrLnNum<>t3.AgrLnNum
					)
					if @m_rows2>0
					begin
							set @error=1
							set @error_message='(PO_010_001)Approver is not allowed to modify critical information in PO.'
							select @error,@error_message 
							return
					end

					-----------------------------------------------------------------
					/*
					Coding ID:PO_010_002
					By:Will
					Date:20131211
					description: Approver can NOT update crtitical field on PO 
					Remark:Coding
					
					*/
					-----------------------------------------------------------------	
					select @m_rows2=COUNT(*)
					from ADOC t0 inner join ADO1 t1
					on t0.DocEntry=t1.DocEntry
					and t0.LogInstanc =t1.LogInstanc inner join 
					(OPOR t2 inner join POR1 t3 on t2.DocEntry =t3.DocEntry)
					on t0.DocEntry =t2.DocEntry
					where t0.DocEntry=@list_of_cols_val_tab_del
					and t0.objtype=@object_type and t1.objtype=@object_type  /*Vince,20140213,t0.objtype=@object_type and*/
					and t0.LogInstanc = (
											select MAX(loginstanc) 
											from ADOC
											where DocEntry=t0.DocEntry
											and objtype=t0.objtype
										)
					and t1.LineNum=t3.LineNum 
					and t2.UserSign<>t2.UserSign2 
					and (t0.CntctCode<>t2.CntctCode
					or t0.NumAtCard<>t2.NumAtCard
					or t0.DocCur<>t2.DocCur
					or t0.DocRate<>t2.DocRate
					or t0.DocDate<>t2.DocDate
					or t0.DocDueDate<>t2.DocDueDate
					or t0.TaxDate<>t2.TaxDate
					or t0.U_m_POver<>t2.U_m_POver
					or convert(varchar(200),t0.u_m_vmemo)<>convert(varchar(200),t2.u_m_vmemo)
					or t0.DocTotal<>t2.DocTotal
					or t0.DocTotalFC<>t2.DocTotalFC
					or t0.DocTotalSy<>t2.DocTotalSy
					or t0.DiscSum<>t2.DiscSum
					or t0.DiscSumFC<>t2.DiscSumFC
					or t0.DiscSumSy<>t2.DiscSumSy
					or t0.DiscPrcnt<>t2.DiscPrcnt
					or t0.SlpCode<>t2.SlpCode
					or t0.OwnerCode<>t2.OwnerCode

					)
					if @m_rows2>0
					begin
							set @error=1
							set @error_message='(PO_010_002)Approver is not allowed to modify critical information in PO. '
							select @error,@error_message 
							return
					end
					
	        
	        
				end

				-------------------------------------------------------------------
				/*
				Coding ID:PO_011
				By:Will
				Date:20131213
				description: Can Not update PO when it is in approval process.
				Remark:Coding
				*/
				-------------------------------------------------------------------		
				set @m_rows=0
				select @m_rows=COUNT(*)
				from OPOR t0 inner join POR1 t1
				on t0.DocEntry=t1.docentry inner join OUSR t2
				on t0.UserSign2=t2.USERID
				where t0.DocEntry =@list_of_cols_val_tab_del
				and t2.USER_CODE not in (
								select distinct t1.Candidate
								from OWLS t0 inner join WLS1 t1
								on t0.WFInstID =t1.WFInstID 
								and t0.TaskID=t1.TaskID
								inner join WLS2 t2
								on t0.WFInstID =t1.WFInstID 
								and t0.TaskID =t1.TaskID
								where t2.ObjectType=convert(nvarchar(20),@object_type)     /*Vince,20140213,convert(nvarchar(20),@object_type)*/
								and t0.ObjType=convert(nvarchar(20),@object_type)        /*Vince,20140213,add new condition*/
								and t2.ObjKey=@list_of_cols_val_tab_del 
								and t1.Candidate<>'workflow'
							)
				and t0.U_submit='Y'
				if @m_rows>0
				begin
           
						set @error=1
						set @error_message='(PO_011)The document in approval process cannot be updated.'
						select @error,@error_message 
						return
				end

				---------------------------------------------------------------------
				--/*
				--Coding ID:PO_012
				--By:Vince
				--Date:20140505
				--description: Can Not delete row in approval.
				--Remark:Coding
				--*/
				---------------------------------------------------------------------		
				--IF (SELECT U_submit FROM OPOR WHERE DocEntry=@list_of_cols_val_tab_del)='Y' 
				--	AND 
				--	(SELECT COUNT(*) FROM OPOR T0 INNER JOIN POR1 T1 ON T0.DocEntry=T1.DocEntry
				--	WHERE T0.DocEntry=@list_of_cols_val_tab_del)
				--	<>
				--	(SELECT COUNT(*) FROM ADOC T0 INNER JOIN ADO1 T1 ON T0.DocEntry=T1.DocEntry 
				--			AND T0.LogInstanc=T1.LogInstanc AND T0.ObjType=T1.ObjType
				--	WHERE T0.DocEntry=@list_of_cols_val_tab_del AND T0.ObjType=22
				--	AND T0.LogInstanc =(SELECT MAX(LogInstanc) FROM ADOC 
				--						WHERE ObjType=22 AND DocEntry=@list_of_cols_val_tab_del))
				--BEGIN
				--		set @error=1
				--		set @error_message='(PO_012)Cannot modify PO!'
				--END

				




End

if (@object_type = '22') and (@transaction_type in ('A','U'))
Begin

					-------------------------------------------------------------------
					/*
					Coding ID:PO2PR_001
					By:Will
					Date:20140112
					description: PO2PR_001_A:quantity can not be over than PR openqty
					             PO2PR_001_B:AMOUNT can not be over than PR amount by rate
								 PO2PR_001_A:AMOUNT can not be over than PR amount by value
					Remark:Coding
					*/
					-------------------------------------------------------------------
					set @m_rows=0
					select @m_rows=COUNT(t5.U_Total)
					from opor t0 inner join por1 t1
					on t0.docentry=t1.docentry
					left outer join 
					adoc t2 inner join ado1 t3
					on t2.docentry=t3.docentry
					and t2.loginstanc=t3.loginstanc
					and t2.ObjType=t3.ObjType 
					on t0.docentry=t2.docentry
					and t0.objtype=t2.objtype
					and t1.linenum=t3.linenum
					and t2.loginstanc = (
						select max(tt0.loginstanc)
						from adoc tt0
						where tt0.docentry=t0.docentry
						and tt0.objtype=t0.objtype
					)
					inner join [@ZMPRD] t4 inner join [@zmpr1] t5
					on t4.DocEntry=t5.DocEntry
					on t1.U_m_PRID=t4.DocNum 
					and t1.U_m_PRLIN=t5.LineId
					inner join [@ZCTLC] t6
					on t0.ObjType=t6.U_toleDoc
					inner join oitm t7
					on t7.itemcode=t1.itemcode left outer join oitm t8
					on t3.ItemCode=t8.ItemCode
					where t0.DocEntry=@list_of_cols_val_tab_del
					group by t1.itemcode ,t5.U_AvailAmnt,t6.U_tolValue
					,t6.U_tolRate,t1.U_m_PRID,t1.U_m_PRLIN,t5.U_Total,t5.U_ReqQTY,t5.U_OpenQTY  
					having t5.U_ReqQTY-(t5.U_ReqQTY-t5.U_OpenQTY)+isnull(sum(t3.openqty*isnull(t8.numinbuy,t7.numinbuy)),0)<sum(t1.openqty*t7.NumInBuy)
				        
					if @m_rows>0
					begin
							set @error=1
							set @error_message='(PO2PR_001_A)The PO quantity is over than referenced PR open quantity.'
							select @error,@error_message
							return
					end

					set @m_rows=0
					select @m_rows=count(t5.U_Total)
					from opor t0 inner join por1 t1
					on t0.docentry=t1.docentry
					left outer join 
					adoc t2 inner join ado1 t3
					on t2.docentry=t3.docentry
					and t2.loginstanc=t3.loginstanc
					and t2.ObjType=t3.ObjType 
					on t0.docentry=t2.docentry
					and t0.objtype=t2.objtype
					and t1.linenum=t3.linenum
					and t2.loginstanc = (
					select max(tt0.loginstanc)
					from adoc tt0
					where tt0.docentry=t0.docentry
					and tt0.objtype=t0.objtype
					)
					inner join [@ZMPRD] t4 inner join [@zmpr1] t5
					on t4.DocEntry=t5.DocEntry
					on t1.U_m_PRID=t4.DocNum 
					and t1.U_m_PRLIN=t5.LineId
					inner join [@ZCTLC] t6
					on t0.ObjType=t6.U_toleDoc
					where t0.docentry=@list_of_cols_val_tab_del
					and t6.U_IsActiv='Y'
					group by t1.itemcode ,t5.U_AvailAmnt,t6.U_tolValue
					,t6.U_tolRate,t1.U_m_PRID,t1.U_m_PRLIN,t5.U_Total,t5.U_ReqQTY,t5.U_OpenQTY
					having (t5.U_Total+isnull(t6.U_tolValue,0)-(t5.U_Total-t5.U_AvailAmnt)+isnull(sum(t3.OpenQty*(case when t3.currency='CNY' then t3.Price else t3.price*t3.rate end)),0)-sum(t1.OpenQty*(case when t1.currency='CNY' then t1.Price else t1.price*t1.rate end))<0
					or t5.U_Total*(1+isnull(t6.U_tolRate/100,0))-(t5.U_Total-t5.U_AvailAmnt)+isnull(sum(t3.OpenQty*(case when t3.currency='CNY' then t3.Price else t3.price*t3.rate end)),0)-sum(t1.OpenQty*(case when t1.currency='CNY' then t1.Price else t1.price*t1.rate end))<0)		--return

					if isnull(@m_rows,0)>0
					begin
										select @m_validQTYBYValue=t5.U_Total+isnull(t6.U_tolValue,0)-(t5.U_Total-t5.U_AvailAmnt)+isnull(sum(t3.OpenQty*(case when t3.currency='CNY' then t3.Price else t3.price*t3.rate end)),0)-sum(t1.OpenQty*(case when t1.currency='CNY' then t1.Price else t1.price*t1.rate end))
										,@m_validQTYBYrate=t5.U_Total*(1+isnull(t6.U_tolRate/100,0))-(t5.U_Total-t5.U_AvailAmnt)+isnull(sum(t3.OpenQty*(case when t3.currency='CNY' then t3.Price else t3.price*t3.rate end)),0)-sum(t1.OpenQty*(case when t1.currency='CNY' then t1.Price else t1.price*t1.rate end))
										from opor t0 inner join por1 t1
										on t0.docentry=t1.docentry
										left outer join 
										adoc t2 inner join ado1 t3
										on t2.docentry=t3.docentry
										and t2.loginstanc=t3.loginstanc
										and t2.ObjType=t3.ObjType 
										on t0.docentry=t2.docentry
										and t0.objtype=t2.objtype
										and t1.linenum=t3.linenum
										and t2.loginstanc = (
										select max(tt0.loginstanc)
										from adoc tt0
										where tt0.docentry=t0.docentry
										and tt0.objtype=t0.objtype
										)
										inner join [@ZMPRD] t4 inner join [@zmpr1] t5
										on t4.DocEntry=t5.DocEntry
										on t1.U_m_PRID=t4.DocNum 
										and t1.U_m_PRLIN=t5.LineId
										inner join [@ZCTLC] t6
										on t0.ObjType=t6.U_toleDoc
										where t0.docentry=@list_of_cols_val_tab_del
										and t6.U_IsActiv='Y'
										group by t1.itemcode ,t5.U_AvailAmnt,t6.U_tolValue
										,t6.U_tolRate,t1.U_m_PRID,t1.U_m_PRLIN,t5.U_Total,t5.U_ReqQTY,t5.U_OpenQTY


										if @m_validQTYBYRate>@m_validQTYBYValue
										begin
										   set @error=1
										   set @error_message='(PO2PR_001_B)The PO amount is over than referenced PR available amount considered rate tolerance.'
										   select @error,@error_message
										   return
										end
										else
										begin
										   set @error=1
										   set @error_message='(PO2PR_001_C)The PO amount is over than referenced PR available amount considered value tolerance.'
										   select @error,@error_message
										   return
										end
					end




				-------------------------------------------------------------------
				/*
				Coding ID:PO2PR_002
				By:Will
				Date:20131211
				description: when PO is be added or update:
				the open Quantity will be decreased in linked PR
				the avaliable amount will be decreased in linke PR
				notes:
				since when update, the old value will be return first. so if old value is greate than req.QTY/ line total, than only req.QTY/ line total will be return.
				Remark:Coding
				*/
				-------------------------------------------------------------------
				
					update [@zmpr1]
					set U_AvailAmnt=U_AvailAmnt+t3.validamnt 
					,U_OpenQTY=U_OpenQTY+t3.openInvQTY
					from [@zmprd] t0 inner join [@zmpr1] t1
					on t0.docentry=t1.docentry inner join
					(
								select dataset.docentry 
								,dataset.lineid 
								,dataset.itemcode 
								,sum(dataset.amnt) validamnt
								,sum(dataset.qty) openInvQTY
								from
								(
														select t4.DocEntry docentry
														,t5.LineId lineid
														, t3.itemcode itemcode
														,sum(t3.OpenQty*(case when t3.currency='CNY' then t3.Price else t3.price*t3.Rate end)) amnt 
														,t5.U_Total
														,sum(t3.OpenQty*isnull(t7.NumInBuy,1)) qty
														,t5.U_ReqQTY
														,t5.U_OpenQTY
														,t5.U_AvailAmnt
														from adoc t2 inner join ado1 t3
														on t2.docentry=t3.docentry
														and t2.loginstanc=t3.loginstanc
														and t2.ObjType=t3.ObjType 
														and t2.loginstanc = (
																				select max(tt0.loginstanc)
																				from adoc tt0
																				where tt0.docentry=t2.docentry
																				and tt0.objtype=t2.objtype
																	)
														inner join [@ZMPRD] t4 inner join [@zmpr1] t5
														on t4.DocEntry=t5.DocEntry
														on t3.U_m_PRID=t4.DocNum 
														and t3.U_m_PRLIN=t5.LineId
														left outer  join [@ZCTLC] t6
														on t2.ObjType=t6.U_toleDoc
														and t6.U_IsActiv='Y'
														inner join oitm t7
														on t3.ItemCode=t7.ItemCode 
														where t2.docentry=@list_of_cols_val_tab_del
														and t3.U_m_PRID is not null
														and isnull(t3.LineStatus,'O')='O'
														group by t3.itemcode ,t5.U_AvailAmnt,t6.U_tolValue
														,t6.U_tolRate,t4.DocEntry 
														,t5.LineId,T3.LineStatus,t5.U_OpenQTY,t5.U_ReqQTY,t5.U_Total,t5.U_ReqQTY,t2.ObjType 
														union all
														select t4.DocEntry docentry
														,t5.LineId lineid
														, t3.itemcode itemcode
														--,-sum(t3.OpenSum) amnt /*linetotal when C/L*/
														,-case when t3.linestatus='C' then 0 else sum(t3.OpenQty*(case when t3.currency='CNY' then t3.Price else t3.price*t3.Rate end)) end amnt
														,t5.U_Total
														,-sum(t3.OpenQty*t7.NumInBuy) qty
														,t5.U_ReqQTY
														,t5.U_OpenQTY
														,t5.U_AvailAmnt
														from opor t2 inner join por1 t3
														on t2.docentry=t3.docentry
														inner join [@ZMPRD] t4 inner join [@zmpr1] t5
														on t4.DocEntry=t5.DocEntry
														on t3.U_m_PRID=t4.DocNum 
														and t3.U_m_PRLIN=t5.LineId
														left outer  join [@ZCTLC] t6
														on t2.ObjType=t6.U_toleDoc
														and t6.U_IsActiv='Y'
														inner join oitm t7
														on t3.ItemCode=t7.ItemCode 
														where t2.docentry=@list_of_cols_val_tab_del
														and t3.U_m_PRID is not null
														group by t3.itemcode ,t5.U_AvailAmnt,t6.U_tolValue
														,t6.U_tolRate,t4.DocEntry 
														,t5.LineId,T3.LineStatus,t5.U_OpenQTY,t5.U_ReqQTY,t5.U_Total,t5.U_ReqQTY,t2.ObjType
						
					)dataset 
					group by dataset.docentry,dataset.itemcode,dataset.lineid,dataset.U_AvailAmnt,dataset.U_Total,dataset.U_ReqQTY,dataset.U_OpenQTY 
                     ) t3 
					on t0.docentry=t3.DocEntry 
					and t1.LineId=t3.LineId 
					and t1.U_ItemCode=t3.ItemCode


				-------------------------------------------------------------------
				/*
				Coding ID:PO2PR_004
				By:Will
				Date:20131223
				description: when open quantity is 0 in PR, the close field on PR line will be closed automatically
				Remark:Coding
				*/
				-------------------------------------------------------------------
				update [@ZMPR1]
				set u_close='C'
				from opor t0 inner join por1 t1
				on t0.docentry=t1.docentry
				left outer join [@ZMPRD] t2 inner join [@ZMPR1] t3
				on t2.docentry=t3.docentry
				on t1.u_m_prid=t2.docnum
				and t1.u_m_prlin=t3.lineid
				where t0.docentry=@list_of_cols_val_tab_del
				and t1.u_m_prid is not null
				and t3.u_openqty=0
								
				-------------------------------------------------------------------
				/*
				Coding ID:PO2PR_005
				By:Will
				Date:20131223
				description: when open quantity great than 0 in PR, the close field on PR line will be opened automatically
				Remark:Coding
				*/
				-------------------------------------------------------------------
				update [@ZMPR1]
				set u_close='O'
				from opor t0 inner join por1 t1
				on t0.docentry=t1.docentry
				left outer join [@ZMPRD] t2 inner join [@ZMPR1] t3
				on t2.docentry=t3.docentry
				on t1.u_m_prid=t2.docnum
				and t1.u_m_prlin=t3.lineid
				where t0.docentry=@list_of_cols_val_tab_del
				and t1.u_m_prid is not null
				and t3.u_openqty<>0

				-------------------------------------------------------------------
				/*
				Coding ID:PO2PR_006
				By:Will
				Date:20140110
				description: when open quantity is not equal to req.quantity, the frozen indicator is YES
				Remark:Coding
				*/
				-------------------------------------------------------------------
				update [@ZMPR1]
				set U_Frozen='Y'
				from opor t0 inner join por1 t1
				on t0.docentry=t1.docentry
				left outer join [@ZMPRD] t2 inner join [@ZMPR1] t3
				on t2.docentry=t3.docentry
				on t1.u_m_prid=t2.docnum
				and t1.u_m_prlin=t3.lineid
				where t0.docentry=@list_of_cols_val_tab_del
				and t1.u_m_prid is not null
				and t3.U_ReqQTY<>t3.U_OpenQTY 

				-------------------------------------------------------------------
				/*
				Coding ID:PO2PR_007
				By:Will
				Date:20140110
				description:  when open quantity is equal to req.quantity, the frozen indicator is NO
				Remark:Coding
				*/
				-------------------------------------------------------------------
				update [@ZMPR1]
				set U_Frozen='N'
				from [@ZMPRD] t2 inner join [@ZMPR1] t3
				on t2.DocEntry=t3.docentry
				where t3.U_ReqQTY=t3.U_OpenQTY 
				
				-------------------------------------------------------------------
				/*
				Coding ID:PO_016
				By:Will
				Date:20131223
				description: when price source is special price for BP,the Blanket agreement id is needed
				Remark:Coding
				*/
				-------------------------------------------------------------------
				select @m_rows=count(*)
				from opor t0 inner join por1 t1
				on t0.docentry=t1.docentry
				where t0.docentry=@list_of_cols_val_tab_del
				and t1.U_m_Prcsr='Y'
				and t1.AgrNo is null
				and U_m_Price>0   /*Vince,20140213,add new condition*/
				if @m_rows>0
				begin

				    set @error=1
					set @error_message='(PO_016)No valid blanket agreement is found for BP special price. Please check if the blanket agreement is approved.'
					select @error,@error_message 
					return
				end
				
				-------------------------------------------------------------------
				/*
				Coding ID:PO_018
				By:Will
				Date:20131224
				description: PO VERSION CHECKED
				Remark:Coding
				*/
				-------------------------------------------------------------------
				select @m_rows=count(*)
				from opor t0 inner join por1 t1
				on t0.docentry=t1.docentry
				where t0.docentry=@list_of_cols_val_tab_del
				and t0.U_m_POver is null
				if @m_rows>0
				begin
				    set @error=1
					set @error_message='(PO_018)PO version is mandatory.'
					select @error,@error_message 
					return
				end

				-------------------------------------------------------------------
				/*
				Coding ID:PO_019
				By:Will
				Date:20140116
				description: PO will apprpoved when doc.total is less than 2000
				Remark:Coding
				*/
				-------------------------------------------------------------------
				update opor 
				set Confirmed='Y'
				,U_approval='9'
				where (DocTotal-VatSum)<(select U_Amount  from [@ZCAPP] where U_DocType ='22') /*Vince,20140318, change condition*/
				and docentry=@list_of_cols_val_tab_del

				-------------------------------------------------------------------
				/*
				Coding ID:PO_020
				By:Will
				Date:20140116
				description: PO cost center should equal to PR cost center
				Remark:Coding
				*/
				-------------------------------------------------------------------
				select @m_rows=count(*)
				from opor t0 inner join por1 t1
				on t0.docentry=t1.docentry 
				inner join 
				[@ZMPRD] t2 inner join [@zmpr1] t3
				on t2.DocEntry=t3.DocEntry 
				on t1.U_m_PRID=t2.DocNum
				and t1.U_m_PRLIN=t3.LineId
				where t0.docentry=@list_of_cols_val_tab_del
				and t1.OcrCode<>t2.U_Cccode
				if @m_rows>0
				begin
				    set @error=1
					set @error_message='(PO_020)The cost center assigned in PO item must be same as referenced PR.'
					select @error,@error_message 
					return
				end

				-------------------------------------------------------------------
				/*
				Coding ID:PO_021
				By:Will
				Date:20140116
				description: PO cost center should equal to PR cost center
				Remark:Coding
				*/
				-------------------------------------------------------------------
				select @m_rows=count(*)
				from opor t0 inner join por1 t1
				on t0.docentry=t1.docentry 
				inner join 
				[@ZMPRD] t2 inner join [@zmpr1] t3
				on t2.DocEntry=t3.DocEntry 
				on t1.U_m_PRID=t2.DocNum
				and t1.U_m_PRLIN=t3.LineId
				where t0.docentry=@list_of_cols_val_tab_del
				and t1.Project<>t2.U_Project
				if @m_rows>0
				begin
				    set @error=1
					set @error_message='(PO_021)The project code assigned in PO item must be same as referenced PR.'
					select @error,@error_message 
					return
				end
 
				

				-------------------------------------------------------------------
				/*
				Coding ID:PO_023
				By:Will
				Date:20140116
				description: PO cost center should equal to PR cost center
				Remark:Coding
				*/
				-------------------------------------------------------------------
				select @m_rows=count(*)
				from opor t0 inner join por1 t1
				on t0.docentry=t1.docentry inner join oitm t2
				on t1.itemcode=t2.itemcode
				where t0.docentry=@list_of_cols_val_tab_del
				and t1.OcrCode is null
				and t2.itmsgrpcod in ('101','102','103','107','110')

				if @m_rows>0
				begin
				    set @error=1
					set @error_message='(PO_023)Cost center is mandatory in PO for indirect item.'
					select @error,@error_message 
					return
				end

				-------------------------------------------------------------------
				/*
				Coding ID:PO_024
				By:Will
				Date:20140122
				description: The project code is mandatory for indirect item
				Remark:Coding
				*/
				-------------------------------------------------------------------
				set @m_rows=0
				select @m_rows=count(*)
				from opor t0 inner join por1 t1
				on t0.docentry=t1.docentry inner join oitm t2
				on t1.itemcode=t2.itemcode
				where t0.docentry=@list_of_cols_val_tab_del
				and (case when isnull(t1.Project,'')='' then 'NO' else t1.Project end)='NO'
				and t2.itmsgrpcod in ('108')

				if @m_rows>0
				begin
				    set @error=1
					set @error_message='(PO_024)Project code is mandatory in PO for project item.'
					select @error,@error_message 
					return
				end
End

if (@object_type = '22') and (@transaction_type in ('C','L'))
Begin
		-------------------------------------------------------------------
				/*
				Coding ID:PO2PR_003
				By:Will
				Date:20131219
				description: When PO update, the old value will be recording in [@ZMUER] table.
				             the below coding will return the value in [@ZMUER] and 
							 update the new value to PR (Open QTY and Avaliable Amount)
				Remark:Coding
				20131212: UPDATE CODE, because the [@ZMUER] table and PO sync.lock cannot be release
				          when other business validation block was be catch.
						  So. 1 Cancel and delete [@ZMUER] and u_m_lock UDF in PO.
						      2 load update information from ADOC and ADO1
							  3 those above setting will be excute after testing pass.
			    20131220:UPDATE CODE: 
				when PO was be close or cancel, the quantity (open inv.quantity) and line total will be return to linked PR
				20140110:update code:
				group by before update
				*/
				-------------------------------------------------------------------
				
				update [@zmpr1]
				set U_AvailAmnt=U_AvailAmnt+t3.validamnt 
					,U_OpenQTY=U_OpenQTY+t3.openInvQTY
				from [@zmprd] t0 inner join [@zmpr1] t1
				on t0.docentry=t1.docentry inner join
				(
					select dataset.docentry 
								,dataset.lineid 
								,dataset.itemcode 
								,sum(dataset.amnt) validamnt
								,sum(dataset.qty) openInvQTY
								from
								(
														select t4.DocEntry docentry
														,t5.LineId lineid
														, t3.itemcode itemcode
														,sum(t3.OpenQty*(case when t3.currency='CNY' then t3.Price else t3.price*t3.rate end)) amnt 
														,t5.U_Total
														,sum(t3.OpenQty*isnull(t7.NumInBuy,1)) qty
														,t5.U_ReqQTY
														,t5.U_OpenQTY
														,t5.U_AvailAmnt
														from adoc t2 inner join ado1 t3
														on t2.docentry=t3.docentry
														and t2.loginstanc=t3.loginstanc
														and t2.ObjType=t3.ObjType 
														and t2.loginstanc = (
																				select max(tt0.loginstanc)
																				from adoc tt0
																				where tt0.docentry=t2.docentry
																				and tt0.objtype=t2.objtype
																	)
														inner join [@ZMPRD] t4 inner join [@zmpr1] t5
														on t4.DocEntry=t5.DocEntry
														on t3.U_m_PRID=t4.DocNum 
														and t3.U_m_PRLIN=t5.LineId
														left outer  join [@ZCTLC] t6
														on t2.ObjType=t6.U_toleDoc
														and t6.U_IsActiv='Y'
														inner join oitm t7
														on t3.ItemCode=t7.ItemCode 
														where t2.docentry=@list_of_cols_val_tab_del
														and t3.U_m_PRID is not null
														and isnull(t3.LineStatus,'O')='O'
														group by t3.itemcode ,t5.U_AvailAmnt,t6.U_tolValue
														,t6.U_tolRate,t4.DocEntry 
														,t5.LineId,T3.LineStatus,t5.U_OpenQTY,t5.U_ReqQTY,t5.U_Total,t5.U_ReqQTY,t2.ObjType 
														union all
														select t4.DocEntry docentry
														,t5.LineId lineid
														, t3.itemcode itemcode
														--,-sum(t3.OpenSum) amnt /*linetotal when C/L*/
														,-case when t3.linestatus='C' then 0 else sum(t3.OpenQty*(case when t3.currency='CNY' then t3.Price else t3.price*t3.rate end)) end amnt
														,t5.U_Total
														,-sum(t3.OpenQty*t7.NumInBuy) qty
														,t5.U_ReqQTY
														,t5.U_OpenQTY
														,t5.U_AvailAmnt
														from opor t2 inner join por1 t3
														on t2.docentry=t3.docentry
														inner join [@ZMPRD] t4 inner join [@zmpr1] t5
														on t4.DocEntry=t5.DocEntry
														on t3.U_m_PRID=t4.DocNum 
														and t3.U_m_PRLIN=t5.LineId
														left outer  join [@ZCTLC] t6
														on t2.ObjType=t6.U_toleDoc
														and t6.U_IsActiv='Y'
														inner join oitm t7
														on t3.ItemCode=t7.ItemCode 
														where t2.docentry=@list_of_cols_val_tab_del
														and t3.U_m_PRID is not null
														group by t3.itemcode ,t5.U_AvailAmnt,t6.U_tolValue
														,t6.U_tolRate,t4.DocEntry 
														,t5.LineId,T3.LineStatus,t5.U_OpenQTY,t5.U_ReqQTY,t5.U_Total,t5.U_ReqQTY,t2.ObjType
				
					
					
					)dataset 
					group by dataset.docentry,dataset.itemcode,dataset.lineid,dataset.U_AvailAmnt,dataset.U_Total,dataset.U_ReqQTY,dataset.U_OpenQTY
				
				) t3 
				on t0.docentry=t3.DocEntry 
				and t1.LineId=t3.LineId 
				and t1.U_ItemCode=t3.ItemCode

				-------------------------------------------------------------------
				/*
				Coding ID:PO2PR_004
				By:Will
				Date:20131223
				description: when open quantity is 0 in PR, the close field on PR line will be closed automatically
				Remark:Coding
				*/
				-------------------------------------------------------------------
				update [@ZMPR1]
				set u_close='C'
				from opor t0 inner join por1 t1
				on t0.docentry=t1.docentry
				left outer join [@ZMPRD] t2 inner join [@ZMPR1] t3
				on t2.docentry=t3.docentry
				on t1.u_m_prid=t2.docnum
				and t1.u_m_prlin=t3.lineid
				where t0.docentry=@list_of_cols_val_tab_del
				and t1.u_m_prid is not null
				and t3.u_openqty=0
								
				-------------------------------------------------------------------
				/*
				Coding ID:PO2PR_005
				By:Will
				Date:20131223
				description: when open quantity great than 0 in PR, the close field on PR line will be opened automatically
				Remark:Coding
				*/
				-------------------------------------------------------------------
				update [@ZMPR1]
				set u_close='O'
				from opor t0 inner join por1 t1
				on t0.docentry=t1.docentry
				left outer join [@ZMPRD] t2 inner join [@ZMPR1] t3
				on t2.docentry=t3.docentry
				on t1.u_m_prid=t2.docnum
				and t1.u_m_prlin=t3.lineid
				where t0.docentry=@list_of_cols_val_tab_del
				and t1.u_m_prid is not null
				and t3.u_openqty<>0

				-------------------------------------------------------------------
				/*
				Coding ID:PO2PR_006
				By:Will
				Date:20140110
				description: when open quantity is not equal to req.quantity, the frozen indicator is YES
				Remark:Coding
				*/
				-------------------------------------------------------------------
				update [@ZMPR1]
				set U_Frozen='Y'
				from opor t0 inner join por1 t1
				on t0.docentry=t1.docentry
				left outer join [@ZMPRD] t2 inner join [@ZMPR1] t3
				on t2.docentry=t3.docentry
				on t1.u_m_prid=t2.docnum
				and t1.u_m_prlin=t3.lineid
				where t0.docentry=@list_of_cols_val_tab_del
				and t1.u_m_prid is not null
				and t3.U_ReqQTY<>t3.U_OpenQTY 

				-------------------------------------------------------------------
				/*
				Coding ID:PO2PR_007
				By:Will
				Date:20140110
				description:  when open quantity is equal to req.quantity, the frozen indicator is NO
				Remark:Coding
				*/
				-------------------------------------------------------------------
				update [@ZMPR1]
				set U_Frozen='N'
				from [@ZMPRD] t2 inner join [@ZMPR1] t3
				on t2.DocEntry=t3.docentry
				where t3.U_ReqQTY=t3.U_OpenQTY 


				-------------------------------------------------------------------
				/*
				Coding ID:PO2PR_008
				By:Will
				Date:20140117
				description:  cannot CLOSE / CANCEL when PO was submited.
				Remark:Coding
				*/
				-------------------------------------------------------------------
				set @m_rows=0
				select @m_rows=count(*)
				from opor t0 inner join por1 t1
				on t0.docentry=t1.docentry
				where t0.docentry=@list_of_cols_val_tab_del
				and t0.U_submit='Y'
				if @m_rows>0
				begin
						set @error=1
						set @error_message='(PO2PR_008)The document in approval process cannot be closed/cancelled'
						select @error,@error_message 
						return

				end

				-------------------------------------------------------------------
				/*
				Coding ID:PO2PR_009
				By:Will
				Date:20140121
				description:  PO cannot CLOSE / CANCEL by Approver.
				Remark:Coding
				*/
				-------------------------------------------------------------------
				set @m_rows=0
				select @m_rows=COUNT(*)
				from OPOR t0 inner join POR1 t1
				on t0.DocEntry=t1.docentry inner join OUSR t2
				on t0.UserSign2=t2.USERID
				where t0.DocEntry =@list_of_cols_val_tab_del
				and t2.USER_CODE in (
											/*get approvor */
											select distinct t1.Candidate
											from OWLS t0 inner join WLS1 t1
											on t0.WFInstID =t1.WFInstID 
											and t0.TaskID=t1.TaskID
											inner join WLS2 t2
											on t0.WFInstID =t1.WFInstID 
											and t0.TaskID =t1.TaskID
											where t2.ObjectType=@object_type 
											and t0.ObjType=@object_type   /*Vince,20140213, add new condition*/
											and t2.ObjKey=@list_of_cols_val_tab_del 
											and t1.Candidate<>'workflow'
										)
	            and t1.OpenQty>0
				
				if @m_rows>0
				begin
				     set @error=1
						set @error_message='(PO2PR_009)The document cannot be closed/cancelled by approver.'
						select @error,@error_message 
						return
				end
		
End

/***********************************************************************
*****************************Goods Receipt PO***************************
***********************************************************************/
if (@object_type='20') and (@transaction_type in ('A'))
Begin
        DECLARE UC CURSOR FOR
		SELECT t0.docentry
		,t1.itemcode
		,t1.linenum
		from opdn t0 inner join pdn1 t1
		on t0.docentry=t1.docentry
		where t0.docentry=@list_of_cols_val_tab_del 
		OPEN UC
		FETCH NEXT FROM UC INTO @m_docentry,@m_itemcode,@m_lineid
		WHILE @@FETCH_STATUS=0
		BEGIN
						
						---------------------------------------------------------------
						/*
						Coding ID:GRPOR_001
						By:Will
						Date:20131203
						description: Over receive control 
						Remark:Coding
						       bedug-20140108
						*/
						---------------------------------------------------------------	
						
						select @m_code=U_IsActiv 
						from [@ZCTLC] t0
						where t0.U_toleDoc='20'
						
						if @m_code='Y'
						begin

											select @m_tRate=isnull(U_tolRate,0)
											,@m_tValue=isnull(U_tolValue,0)
											from [@ZCTLC] t0
											where t0.U_toleDoc='20'
											and t0.U_IsActiv='Y'

											select @m_qty=t1.quantity
											,@m_basedocnum=t1.BaseDocNum 
											,@m_baseline=t1.BaseLine
											,@m_cc=t0.CANCELED
											from OPDN t0 inner join pdn1 t1
											on t0.docentry=t1.docentry
											where t0.docentry=@m_docentry
											and t1.LineNum=@m_lineid

 											select @m_pqty=t1.quantity
											from opor t0 inner join por1 t1
											on t0.docentry=t1.docentry
											where t0.DocNum=@m_basedocnum
											and t1.LineNum=@m_baseline
											and t1.ItemCode=@m_itemcode
						

											select @m_hisqty=isnull(sum(t1.quantity),0)-@m_qty
											from OPDN t0 inner join pdn1 t1
											on t0.docentry=t1.docentry
											where t1.BaseType='22'/*PO*/ 
											and t1.BaseDocNum=@m_basedocnum
											and t1.BaseLine=@m_baseline
											and t1.ItemCode=@m_itemcode
											and t0.CANCELED='N'
											group by t1.BaseDocNum 
											,t1.ItemCode
						
											select @m_rqty=isnull(SUM(t1.quantity),0)
											from ORPD t0 inner join RPD1 t1
											on t0.DocEntry=t1.DocEntry 
											inner join
											OPDN t2 inner join PDN1 t3
											on t2.DocEntry =t3.DocEntry 
											on t1.BaseType=t2.ObjType 
											and t1.BaseEntry =t2.DocEntry 
											and t1.BaseLine =t3.LineNum
											where t3.BaseType='22'
											and t3.BaseDocNum=@m_basedocnum
											and t3.BaseLine=@m_baseline
											and t3.ItemCode=@m_itemcode
											and t0.CANCELED='N'
						

											select @m_cdQTY=isnull(SUM(t1.Quantity),0)
										    from orpc t0 inner join rpc1 t1
											on t0.DocEntry=t1.docentry
											inner join 
											opch t2 inner join pch1 t3
											on t2.DocEntry=t3.docentry
											on t1.BaseType=t2.ObjType 
											and t1.BaseEntry =t2.DocEntry 
											and t1.BaseLine =t3.LineNum
											inner join
											OPDN t4 inner join PDN1 t5
											on t4.DocEntry =t5.DocEntry 
											on t3.BaseType=t4.ObjType 
											and t3.BaseEntry =t4.DocEntry 
											and t3.BaseLine =t5.LineNum
											where t5.BaseType='22'
											and t5.BaseDocNum=@m_basedocnum
											and t5.BaseLine=@m_baseline
											and t5.ItemCode=@m_itemcode
											and t0.CANCELED='N'
											--group by t0.CANCELED
						
											set @m_validQTYBYValue=@m_pqty+isnull(@m_tValue,0)-isnull(@m_hisqty,0)+isnull(@m_rqty,0)+isnull(@m_cdQTY,0)
											
											set @m_validQTYBYRate=(@m_pqty*(1+isnull(@m_tRate,0)/100))-isnull(@m_hisqty,0)+isnull(@m_rqty,0)+isnull(@m_cdQTY,0)
						
											if @m_validQTYBYValue>@m_validQTYBYRate and @m_cc='N'
											begin
													if @m_qty>isnull(@m_validQTYBYRate,0)
													begin
															set @error=1
															set @error_message='(GRPOR_001)The item:'+@m_itemcode+' is over than max. receiving quantity considered rate tolerance.'
															select @error,@error_message

													end
											end
											else
											if @m_validQTYBYValue<=@m_validQTYBYRate and @m_cc='N'
											begin
													if @m_qty>isnull(@m_validQTYBYValue,0)
													begin
															set @error=1
															set @error_message='(GRPOR_001)The item:'+@m_itemcode+' is over than max. receiving quantity considered value tolerance.'
															select @error,@error_message

													end
						                    end
											
						

													--/*debug coding*/
													--   set @error=1
													--   set @error_message='PO QTY='+convert(nvarchar(20),isnull(@m_pqty,0))+
													--					  ' GRPO QTY(this time)='+convert(nvarchar(20),isnull(@m_qty,0))+
													--					  ' GRPO QTY(historical)='+convert(nvarchar(20),isnull(@m_hisqty,0))+
													--									 ' Goods return='+convert(nvarchar(20),isnull(@m_rqty,0))+
													--									 ' Credit memo='+convert(nvarchar(20),isnull(@m_cdQTY,0))+
													--									 ' max By Value='+convert(nvarchar(20),isnull(@m_validQTYBYValue,0))+
													--									 ' max By Rate='+convert(nvarchar(20),isnull(@m_validQTYBYRate,0))+
													--									 ' Doc type='+@m_cc
													--   select @error,@error_message
						end
					---------------------------------------------------------------------
					/*
					Ending ID:GRPOR_001
					*/
					-------------------------------------------------------------------
					 
					 
				-------------------------------------------------------------------
				/*
				Coding ID:GRPOR_002
				By:Will
				Date:20131203
				description: The expiration date check when item is managed by B/N or S/N and expirection date check is active in master data
				Remark:Coding
				*/
				-------------------------------------------------------------------
				select @m_ManBtchNum=t2.ManBtchNum
				,@m_ManSerNum=t2.ManSerNum
				from OITM t2
				where t2.ItemCode=@m_itemcode
				
				/*check when item managed by batch number*/
				if @m_ManSerNum='N' and @m_ManBtchNum='Y'
				begin
					set @m_rows=0
					select @m_rows=COUNT(*)
					from OBTN t0 inner join IBT1 t1
					on t0.ItemCode=t1.ItemCode 
					and t0.DistNumber=t1.BatchNum inner join OITM t2
					on t0.ItemCode=t2.ItemCode
					where t1.basetype=@object_type
					and t1.BaseEntry=@list_of_cols_val_tab_del
					and t0.ExpDate is null
					and t2.u_m_expdate ='Y'
					and t1.BaseLinNum=@m_lineid 
			
					if @m_rows>0
					begin
						set @error=1
						set @error_message='(GRPOR_002)The expiration date is manadatory'
						select @error,@error_message 
					end  	
				end
				
				/*check when item managed by serial number*/
				if @m_ManSerNum='Y' and @m_ManBtchNum='N'
				begin
					set @m_rows=0
					select @m_rows=COUNT(*)
					from osrn t0 inner join SRI1 t1
					on t0.ItemCode =t1.ItemCode 
					and t0.SysNumber=t1.SysSerial inner join OITM t2
					on t0.ItemCode=t2.ItemCode
					where t1.basetype=@object_type
					and t1.BaseEntry=@list_of_cols_val_tab_del
					and t0.ExpDate is null
					and t2.u_m_expdate ='Y'
			        and t1.BaseLinNum=@m_lineid 
					if @m_rows>0
					begin
						set @error=1
						set @error_message='(GRPOR_002)The expiration date is manadatory'
						select @error,@error_message 
					end  	
				end
				
				
				-------------------------------------------------------------------
				/*
				Coding ID:GRPOR_003
				By:Will
				Date:20131203
				description: If the Item cost should great than 0, but item cost is not match this rule, User can not input it.
				Remark:Coding
				
				TODO:
				Update by:Robin
				Date:20140805
				Description: If OWHS.D_WarehouseCost is “1-Must be zero”, then skip this validation
				*/
				-------------------------------------------------------------------
			        set @m_rows=0
					select @m_rows=count(*)
					from opdn t0 inner join pdn1 t1
					on t0.docentry=t1.docentry inner join oitm t2
					on t1.ItemCode=t2.ItemCode inner join oitb t3
					on t2.ItmsGrpCod=t3.ItmsGrpCod inner join oitw t4
					on t1.ItemCode=t4.ItemCode 
					and t1.WhsCode=t4.WhsCode 
					where t0.docentry=@list_of_cols_val_tab_del
					and t3.U_m_zc='N'
					and (t2.AvgPrice=0 and t4.AvgPrice=0)
					and t1.linenum=@m_lineid

					if @m_rows>0
					begin
						set @error=1
						set @error_message='(GRPOR_003)The item standard cost of :'+@m_itemcode+' is missing, please notify finance staff to modify it.'
						select @error,@error_message 
					end

					-------------------------------------------------------------------
					/*
					Coding ID:GRPOR_004
					By:Will
					Date:20131218
					description: Inspection QC warehouse only,when Inventory item is incoming
					Remark:Coding
					*/
					-------------------------------------------------------------------
					set @m_rows=0
					select @m_rows=count(*)
					from opdn t0 inner join pdn1 t1
					on t0.docentry=t1.docentry inner join owhs t2
					on t1.WhsCode=t2.WhsCode inner join oitm t3
					on t1.itemcode=t3.itemcode
					where t0.docentry=@list_of_cols_val_tab_del
					and t3.InvntItem='Y'
					and isnull(t2.U_beas_lck,'NO')<>'W'
					and t1.linenum=@m_lineid
					 
					if @m_rows>0
					begin
						set @error=1
						set @error_message='(GRPOR_004)Item:'+@m_itemcode+' must be received to incoming QC inspection warehouse.'
						select @error,@error_message
					end
					 
					 

		FETCH NEXT FROM UC INTO @m_docentry,@m_itemcode,@m_lineid
		END

		CLOSE UC
		DEALLOCATE UC
		
		
		-------------------------------------------------------------------
		/*
		Coding ID:GRPO_001
		By:Will
		Date:20131104
		description: Direct item is only received by Stock-Keeper
		Remark:Coding
		*/
		-------------------------------------------------------------------	
		set @m_rows=0
		select @m_rows=COUNT(*)
		from OPDN t0 inner join PDN1 t1
		on t0.DocEntry=t1.DocEntry inner join OUSR t2
		on t0.UserSign=t2.USERID inner join OITM t3
		on t1.ItemCode =t3.ItemCode 
		where t0.DocEntry=@list_of_cols_val_tab_del
		and isnull(t2.u_m_role,'')<>'SK'
		and t3.ItmsGrpCod in ('104','105','106')

		if @m_rows>0
		begin
				set @error=1
				set @error_message='(GRPO_001)Only stock-keeper can receive direct item.'
				select @error,@error_message 
				return

		end

		-------------------------------------------------------------------
		/*
		Coding ID:GRPO_002
		By:Will
		Date:20131104
		description: Indirect item is only received by Stock-Keeper or PR creator
		Remark:Coding
		*/
		-------------------------------------------------------------------	
		set @m_rows=0
		select @m_rows=count(*)
		from opdn t0 inner join pdn1 t1
		on t0.docentry=t1.docentry inner join 
		opor t2 inner join por1 t3
		on t2.docentry=t3.docentry 
		on t1.basetype=t2.objtype
		and t1.baseentry=t2.docentry
		and t1.baseline=t3.linenum left outer join 
		[@ZMPRD] t4 inner join [@ZMPR1] t5
		on t4.docentry=t5.docentry
		on t3.u_m_prid=t4.docentry
		and t3.u_m_prlin=t5.lineid inner join oitm t6
		on t6.itemcode=t1.itemcode inner join ousr t7
		on t0.UserSign=t7.USERID
		where t0.DocEntry=@list_of_cols_val_tab_del
		and t0.UserSign<>ISNULL(t4.U_UserSign,'')  /*Vince, 20140314,ISNULL*/
		/*Vince,20140422*/
		--and isnull(t7.U_m_role,'NO') not in ('SK','AD')
		and (isnull(t7.U_m_role,'NO')<>'SK' and t7.SUPERUSER<>'Y')
		and t6.ItmsGrpCod not in ('104','105','106')
		and t0.CANCELED='N'
		if @m_rows>0
		begin
				set @error=1
				set @error_message='(GRPO_002A)Only stock-keeper or PR creator can receive indirect item.'
				select @error,@error_message 
				return

		end
		set @m_rows=0
		select @m_rows=COUNT(*)
		from opdn t0 inner join pdn1 t1
		on t0.docentry=t1.docentry 
		inner join 
		OITM t2
		on t1.ItemCode=t2.ItemCode 
		inner join 
		opdn t3 inner join pdn1 t4
		on t3.docentry=t4.docentry 
		on t1.BaseType=t3.ObjType 
		and t1.BaseEntry =t3.DocEntry 
		and t1.BaseLine =t4.LineNum 
		inner join 
		OPOR t5 inner join POR1 t6
		on t5.DocEntry=t6.DocEntry
		on t4.BaseType =t5.ObjType 
		and t4.BaseEntry =t5.DocEntry 
		and t4.LineNum=t6.LineNum 
		inner join
		[@ZMPRD] t7 inner join [@ZMPR1] t8
		on t7.DocEntry =t8.DocEntry 
		on t6.U_m_PRID=t7.DocNum 
		and t6.U_m_PRLIN=t8.LineId
		inner join ousr t9
		on t0.UserSign=t9.USERID
		where t0.DocEntry=@list_of_cols_val_tab_del
		and t2.ItmsGrpCod not in ('104','105','106')
		and t0.CANCELED='C'
		/*Vince, 20140422*/
		--and isnull(t9.U_m_role,'NO') not in ('SK','AD')
		and (isnull(t9.U_m_role,'NO') <>'SK' and t9.SUPERUSER<>'Y')
		and t0.UserSign<>ISNULL(t7.U_UserSign,'')
		
		if @m_rows>0
		begin
				set @error=1
				set @error_message='(GRPO_002B)Only stock-keeper or PR creator can cancel GRPO for indirect item.'
				select @error,@error_message 
				return

		end

		-----------------------------------------------------------------
		/*
		Coding ID:GRPO_003
		By:Will
		Date:20131104
		description: GRPO have to based on PO
		Remark:Coding
		*/
		-----------------------------------------------------------------	
		set @m_rows=0
		select @m_rows=count(*)
		from opdn t0 inner join pdn1 t1
		on t0.docentry=t1.docentry
		where t0.docentry=@list_of_cols_val_tab_del
		and t1.BaseEntry is null
		and t0.canceled not in ('C','Y')
		
		if @m_rows>0
		begin
		   set @error=1
		   set @error_message='(GRPO_003)GRPO must be based on valid PO.'
		   select @error,@error_message
		   return
		end

		

		-------------------------------------------------------------------
		/*
		Coding ID:GRPO_005
		By:Will
		Date:20131223
		description: cannot add GRPO for business block vendor
		Remark:Coding
		*/
		-------------------------------------------------------------------	
	    set @m_rowcount=0
		select @m_rowcount=COUNT(*)
		from opdn t0 inner join ocrd t1
		on t0.CardCode=t1.CardCode
		where u_m_bsnssblk='Y'
		and t0.DocEntry=@list_of_cols_val_tab_del
		if @m_rowcount>0
		begin
				set @error=1
				set @error_message='(GRPO_005)The vendor is blocked for business transactions.'
				select @error,@error_message
				return

		end

		-------------------------------------------------------------------
		/*
		Coding ID:GRPO_006
		By:Will
		Date:20140116
		description: Standard cost have to greate than 0 validation
		Remark:Coding
		*/
		-------------------------------------------------------------------	
		set @m_rows=0
		select @m_rows=count(*)
		from opdn t0 inner join pdn1 t1
		on t0.docentry=t1.docentry inner join oitm t2
		on t1.ItemCode=t2.ItemCode inner join oitw t4
		on t1.ItemCode=t4.ItemCode 
		and t1.WhsCode=t4.WhsCode 
		where t0.docentry=@list_of_cols_val_tab_del
		and (t2.AvgPrice=0 or t4.AvgPrice=0)
		and t0.CANCELED='N'
		and t2.ItmsGrpCod in('104','105','106')
		if @m_rows>0
		begin
			set @error=1
			set @error_message='(GRPO_006) The item standard cost is missing, please notify finance staff to modify it.'
			select @error,@error_message 
			return

		end

		-------------------------------------------------------------------
		/*
		Coding ID:GRPO_007
		By:Will
		Date:20140116
		description: Standard cost have to greate than 0 validation
		Remark:Coding
		*/
		-------------------------------------------------------------------	
		set @m_rows=0
		select @m_rows=count(*)
		from opdn t0 inner join pdn1 t1
		on t0.docentry=t1.docentry inner join oitm t2
		on t1.ItemCode=t2.ItemCode 
		where t0.docentry=@list_of_cols_val_tab_del
		and t1.whscode<>isnull(t2.DfltWH,'930')
		and t0.CANCELED='N'
		and t2.InvntItem='N'
		if @m_rows>0
		begin
			set @error=1
			set @error_message='(GRPO_007)Non warehouse managed item must be received to warehouse 930.'
			select @error,@error_message 
			return

		end
		

		--update beas_qsfthaupt 
		--set abgkz='J'
		--from beas_qsfthaupt t0 inner join opdn t1
		--on t0.basedocentry=t1.DocEntry
		--where t1.DocEntry=@list_of_cols_val_tab_del
		--and t1.CANCELED='C'
	

End

/***********************************************************************
***********************Goods Return(Procurement)************************
***********************************************************************/
if (@object_type = '21') and (@transaction_type in ('A'))
Begin
		
		set @m_rowcount=0
		select @m_rowcount=count(*)
		from orpd t0 inner join rpd1 t1
		on t0.docentry=t1.docentry
		where t0.docentry=@list_of_cols_val_tab_del

		set @m_currline=0
		while @m_currline<=@m_rowcount-1
		begin /*while begin*/
					-------------------------------------------------------------------
					/*
					Coding ID:GoodsReturn_ROW_002
					By:Will
					Date:20131202
					description: recording PO information on Goods Return 
					Remark:Coding
					*/
					-------------------------------------------------------------------	
					/*value PO number and PO line number to var.*/
					select @m_basedocnum=t1.BaseDocNum
					,@m_baseline=t1.BaseLine 
					from opdn t0 inner join pdn1 t1
					on t0.docentry=t1.docentry
					where t0.DocNum in (
										/*get GR_docNum from current GoodsReturn*/
										select distinct t1.U_m_GRPOID
										from ORPD t0 inner join RPD1 t1
										on t0.DocEntry =t1.DocEntry 
										where t0.docentry=@list_of_cols_val_tab_del
										and t1.LineNum=@m_currline)
					and t1.LineNum in(/*get GR_LineNum from current GoodsReturn*/
										select distinct t1.U_m_GRPOLN
										from ORPD t0 inner join RPD1 t1
										on t0.DocEntry =t1.DocEntry 
										where t0.docentry=@list_of_cols_val_tab_del
										and t1.LineNum=@m_currline)
					/*
						update PO number and PO line number in Goods return lines
						Cancel this feature, vince, 20140311
					*/

					--update rpd1
					--set u_m_ponum=@m_basedocnum
					--,u_m_poline=@m_baseline
					--where docentry=@list_of_cols_val_tab_del
					--and LineNum=@m_currline

									
					-------------------------------------------------------------------
					/*
					Coding ID:GoodsReturn_ROW_003
					By:Will
					Date:20131202
					description: the system will update returnQTY in GRPO line when Goods return is based on invoiced GRPO.
					Remark:Coding
					*/
					-------------------------------------------------------------------	
					set @m_rows=0
					select @m_rows=count(*)
					from ORPD t0 inner join RPD1 t1
					on t0.DocEntry =t1.DocEntry inner join OITM t2
					on t1.ItemCode =t2.ItemCode 
					where t0.DocEntry =@list_of_cols_val_tab_del
					and t2.InvntItem='Y'
					and t1.U_m_GRPOID is not null
					and t1.LineNum=@m_currline

					if @m_rows>=1
					begin
							
											
							select @m_basedocnum=t1.U_m_GRPOID 
							,@m_baseline =t1.U_m_GRPOLN
							,@m_rqty=t1.Quantity
							from ORPD t0 inner join RPD1 t1
							on t0.DocEntry =t1.DocEntry 
							where t0.DocEntry =@list_of_cols_val_tab_del
							and t1.LineNum=@m_currline

							update PDN1 
							set u_m_rtnQTY=isnull(u_m_rtnQTY,0)+@m_rqty
							where DocEntry=(select distinct docentry from opdn where docnum=@m_basedocnum)
							and LineNum=@m_baseline
					end

					
				set @m_currline=@m_currline+1
		
		end /*while end*/



		-------------------------------------------------------------------
		/*
		Coding ID:GoodsReturn_001_01
		By:Will
		Date:20131202
		description: The goods return must based on GRPO or invoiced GRPO.
		Remark:Coding
		*/
		-------------------------------------------------------------------
		set @m_rows=0
		select @m_rows=count(*)
		from ORPD t0 inner join RPD1 t1
		on t0.DocEntry =t1.DocEntry inner join OITM t2
		on t1.ItemCode =t2.ItemCode 
		where t0.DocEntry =@list_of_cols_val_tab_del
		and t2.InvntItem='Y'
		 /*Vince, 2040313,change condition*/
		and t1.BaseType=-1
		and (ISNULL(t1.U_m_GRPOID,'')='' or ISNULL(t1.U_m_GRPOLN,'')='')
		and t1.BaseType<>'21'

		if @m_rows<>0
		begin
				set @error=1
				set @error_message='(GoodsReturn_001)Goods return must be based on GRPO (invoiced or not invoiced).'
				select @error,@error_message
				return
		end

		
		-------------------------------------------------------------------
		/*
		Coding ID:GoodsReturn_001_02
		By:Vince
		Date:20140313
		description: The goods return must based on GRPO or invoiced GRPO.
		Remark:Coding
		*/
		-------------------------------------------------------------------
		set @m_rows=0
		select @m_rows=count(*)
		from ORPD t0 inner join RPD1 t1
		on t0.DocEntry =t1.DocEntry inner join OITM t2
		on t1.ItemCode =t2.ItemCode 
		where t0.DocEntry =@list_of_cols_val_tab_del
		and t2.InvntItem='Y'
		 /*Vince, 2040313,change condition*/
		and t1.BaseType<>-1
		and ((ISNULL(t1.U_m_GRPOID,'')<>'' or ISNULL(t1.U_m_GRPOLN,'')<>''))
		and t1.BaseType<>'21'

		if @m_rows>0
		begin
				set @error=1
				set @error_message='(GoodsReturn_002)Goods return must be based on GRPO (invoiced or not invoiced).'
				select @error,@error_message
				return
		end


		-------------------------------------------------------------------
		/*
		Coding ID:GoodsReturn_003
		By:Will
		Date:20131202
		description: The Uom name must equal between GRPO and Goods Return
		Remark:Coding
		*/
		-------------------------------------------------------------------	    
		set @m_rows=0
		select @m_rows=COUNT(*)
		from opdn t0 inner join PDN1 t1
		on t0.DocEntry=t1.DocEntry 
		inner join 
		ORPD t2 inner join RPD1 t3
		on t2.DocEntry=t3.DocEntry
		on t3.U_m_GRPOID=t0.DocEntry
		and t3.U_m_GRPOLN=t1.LineNum 
		where t3.U_m_GRPOID is not null
		and t3.U_m_GRPOLN is not null
		and t2.DocEntry =@list_of_cols_val_tab_del
		and t1.UseBaseUn<>t3.UseBaseUn 
		if @m_rows>0
		begin
		set @error=1
		set @error_message='(GoodsReturn_003)Goods return UoM must be same as GRPO UoM.'
		select @error,@error_message
				return
		end

		-------------------------------------------------------------------
		/*
		Coding ID:GoodsReturn_004
		By:Will
		Date:20131202
		description: The return warehouse should be RTV
		Remark:Coding
		*/
		-------------------------------------------------------------------	    
		set @m_rows=0
		select @m_rows=COUNT(*)
		from ORPD t0 inner join RPD1 t1
		on t0.DocEntry=t1.DocEntry inner join owhs t2
		on t1.whscode=t2.whscode
		where isnull(t2.U_beas_lck,'NONE')<>'Y'
		and t0.DocEntry =@list_of_cols_val_tab_del
		
		if @m_rows>0
		begin
			set @error=1
			set @error_message='(GoodsReturn_004)Goods return can only be from RTV warehouse.'
			select @error,@error_message
				return
		end

		-------------------------------------------------------------------
		/*
		Coding ID:GoodsReturn_005
		By:Will
		Date:20140116
		description: cannot add GoodsReturn for business block vendor
		Remark:Coding
		*/
		-------------------------------------------------------------------	
	    set @m_rowcount=0
		select @m_rowcount=COUNT(*)
		from ORPD t0 inner join ocrd t1
		on t0.CardCode=t1.CardCode
		where u_m_bsnssblk='Y'
		and t0.docentry=@list_of_cols_val_tab_del
		if @m_rowcount>0
		begin
				set @error=1
				set @error_message='(GoodsReturn_005)The vendor is blocked for business transactions.'
				select @error,@error_message
				return
		end

		-------------------------------------------------------------------
		/*
		Coding ID:GoodsReturn_006
		By:Will
		Date:20131223
		description: cannot add GoodsReturn for business block vendor
		Remark:Coding
		*/
		-------------------------------------------------------------------	
		set @m_rowcount=0
		select @m_rowcount=count(*)
		from ORPD t0 inner join RPD1 t1
		on t0.DocEntry =t1.DocEntry
		inner join 
		opdn t2 inner join pdn1 t3
		on t2.DocEntry =t3.DocEntry
		on t1.U_m_GRPOID=t2.DocNum
		and t1.U_m_GRPOLN=t3.LineNum
		where t0.DocEntry =@list_of_cols_val_tab_del
		and ((case isnull(t1.OcrCode,'') when '' then '00' else t1.ocrcode end)<>(case isnull(t3.OcrCode,'') when '' then '00' else t3.ocrcode end)
		or (case isnull(t1.project,'') when '' then '00' else t3.project end)<>(case isnull(t3.project,'') when '' then '00' else t3.project end))
		and t1.U_m_GRPOID is not null
		and t1.U_m_GRPOLN is not null
		if @m_rowcount>0
		begin
				set @error=1
				set @error_message='(GoodsReturn_006)The cost center / project in goods return must be same as referenced GRPO.'
				select @error,@error_message
				return
		end

		-------------------------------------------------------------------
		/*
		Coding ID:GoodsReturn_007
		By:Will
		Date:20131223
		description: cannot add GoodsReturn for business block vendor
		Remark:Coding
		*/
		-------------------------------------------------------------------	
		set @m_rowcount=0
		select @m_rowcount=count(*)
		from ORPD t0 inner join RPD1 t1
		on t0.DocEntry =t1.DocEntry
		inner join 
		opdn t2 inner join pdn1 t3
		on t2.DocEntry =t3.DocEntry
		on t1.U_m_GRPOID=t2.DocNum
		and t1.U_m_GRPOLN=t3.LineNum
		where t0.DocEntry =@list_of_cols_val_tab_del
		and t1.Price<>t3.Price
		and t1.U_m_GRPOID is not null
		and t1.U_m_GRPOLN is not null
		if @m_rowcount>0
		begin
				set @error=1
				set @error_message='(GoodsReturn_007)The unit price must be equal to referenced GRPO.'
				select @error,@error_message
				return
		end

		-------------------------------------------------------------------
		/*
		Coding ID:GoodsReturn_008
		By:Will
		Date:20131223
		description: cannot add GoodsReturn for business block vendor
		Remark:Coding
		*/
		-------------------------------------------------------------------	
		set @m_rowcount=0
		select @m_rowcount=count(*)
		from ORPD t0 inner join RPD1 t1
		on t0.DocEntry =t1.DocEntry
		inner join 
		opdn t2 inner join pdn1 t3
		on t2.DocEntry =t3.DocEntry
		on t1.U_m_GRPOID=t2.DocNum
		and t1.U_m_GRPOLN=t3.LineNum
		where t0.DocEntry =@list_of_cols_val_tab_del
		and t1.unitMsr<>t3.unitMsr
		and t1.U_m_GRPOID is not null
		and t1.U_m_GRPOLN is not null
		if @m_rowcount>0
		begin
				set @error=1
				set @error_message='(GoodsReturn_008)The unit name must be same as referenced GRPO.'
				select @error,@error_message
				return
		end

		-------------------------------------------------------------------
		/*
		Coding ID:GoodsReturn_009
		By:Will
		Date:20140121
		description: the cost center / project code have to equal to its GRPO
		Remark:Coding
		*/
		-------------------------------------------------------------------	
		set @m_rowcount=0
		select @m_rowcount=count(*)
		from ORPD t0 inner join RPD1 t1
		on t0.DocEntry =t1.DocEntry
		inner join 
		opdn t2 inner join pdn1 t3
		on t2.DocEntry =t3.DocEntry
		on t1.BaseType='20'
		and t1.BaseEntry=t2.DocEntry
		and t1.BaseLine=t3.LineNum
		where t0.DocEntry =@list_of_cols_val_tab_del
		and ((case isnull(t1.OcrCode,'') when '' then '00' else t1.ocrcode end)<>(case isnull(t3.OcrCode,'') when '' then '00' else t3.ocrcode end)
		or (case isnull(t1.project,'') when '' then '00' else t3.project end)<>(case isnull(t3.project,'') when '' then '00' else t3.project end))
		and t1.BaseType='20'
		and t1.BaseEntry is not null
		and t1.BaseLine is not null
		if @m_rowcount>0
		begin
				set @error=1
				set @error_message='(GoodsReturn_009)The cost center / project in goods return must be same as referenced GRPO.'
				select @error,@error_message
				return
		end
		
		
End

/***********************************************************************
***********************Purchase Request (B1)************************
***********************************************************************/
if (@object_type = '1470000113') and (@transaction_type in ('A','U'))
Begin
	-------------------------------------------------------------------
	/*
		Coding ID:SBOPR_001
		By:Will
		Date:20131106
		description: Disable SBO delivered PR
		Remark:Coding
		20131106:
	*/
	-------------------------------------------------------------------
   set @error=1
   set @error_message='(SBOPR_001)This is not a valid document for HBAS. Please make sure the HBAS add-on is launched correctly. '
   select @error,@error_message 
   return

End

/***********************************************************************
***********************Goods Receipt ************************
***********************************************************************/
if (@object_type = '59') and (@transaction_type in ('A'))
Begin
		set @m_rowcount=0
		select @m_rowcount=count(*)
		from oign t0 inner join ign1 t1
		on t0.docentry=t1.docentry
		where t0.docentry=@list_of_cols_val_tab_del

		set @m_currline=0
		while @m_currline<=@m_rowcount-1
		begin /*while begin*/
		        
				-------------------------------------------------------------------
				/*
				Coding ID:GR_001
				By:Will
				Date:20131217
				description: If the Item cost should great than 0, but item cost is not match this rule, User can not input it.
				Remark:Coding
				*/
				-------------------------------------------------------------------	
				set @m_rows=0
				select @m_rows=count(*)
				from oign t0 inner join ign1 t1
				on t0.docentry=t1.docentry inner join oitm t2
				on t1.ItemCode=t2.ItemCode inner join oitw t4
				on t1.ItemCode=t4.ItemCode 
				and t1.WhsCode=t4.WhsCode 
				where t0.docentry=@list_of_cols_val_tab_del
				and (t2.AvgPrice=0 or t4.AvgPrice=0)
				and t1.linenum=@m_currline
				and t2.ItmsGrpCod in ('104','105','106') 
				if @m_rows>0
				begin
					set @error=1
					set @error_message='(GR_001)The item standard cost of line '+convert(varchar(10),@m_currline+1)+' is missing, please notify finance staff to modify it.'
					select @error,@error_message 
					return

				end  	

				set @m_currline=@m_currline+1
		
		end /*while end*/



End

/***********************************************************************
***********************Inventory Posting************************
***********************************************************************/
if (@object_type = '10000071') and (@transaction_type in ('A'))
Begin
		set @m_rowcount=0
		select @m_rowcount=count(*)
		from oiqr t0 inner join iqr1 t1
		on t0.docentry=t1.docentry
		where t0.docentry=@list_of_cols_val_tab_del

		set @m_currline=0
		while @m_currline<=@m_rowcount-1
		begin /*while begin*/
		        
				-------------------------------------------------------------------
				/*
				Coding ID:INP_001
				By:Will
				Date:20131217
				description: If the Item cost should great than 0, but item cost is not match this rule, User can not input it.
				Remark:Coding
				*/
				-------------------------------------------------------------------	
				
				set @m_rows=0		
				select @m_rows=count(*)
				from oiqr t0 inner join iqr1 t1
				on t0.docentry=t1.docentry inner join oitm t2
				on t1.ItemCode=t2.ItemCode inner join oitb t3
				on t2.ItmsGrpCod=t3.ItmsGrpCod inner join oitw t4
				on t1.ItemCode=t4.ItemCode 
				and t1.WhsCode=t4.WhsCode 
				where t0.docentry=@list_of_cols_val_tab_del
				and t3.U_m_zc='N'
				and (t2.AvgPrice=0 or t4.AvgPrice=0)
				and t1.DocLineNum=@m_currline

				if @m_rows>0
				begin
					set @error=1
					set @error_message='(INP_001)The item standard cost of line '+convert(varchar(10),@m_currline+1)+' is missing, please notify financial staff to modify it.'
					select @error,@error_message 
					return

				end  	
				set @m_currline=@m_currline+1
		
		end /*while end*/
End

/***********************************************************************
***********************Authorizaiton in BEAS************************
***********************************************************************/
if (@object_type = 'ZMIAT') and (@transaction_type in ('A','U'))
Begin
		-------------------------------------------------------------------
		/*
		Coding ID:ZMIAT_001
		By:Will
		Date:20131220
		description: No duplicated user
		Remark:Coding
		*/
		-------------------------------------------------------------------	
		set @m_rows=0
		select @m_rows=count(t0.U_Userid)
		from [@ZMIAT] t0
		where t0.U_Userid in (
								select t0.U_Userid
								from [@ZMIAT] t0
								where t0.docentry=@list_of_cols_val_tab_del
								)
	    if @m_rows>1
		begin
				set @error=1
				set @error_message='(ZMIAT_001)Current user already exists.'
				select @error,@error_message 
				return
		end

		-------------------------------------------------------------------
		/*
		Coding ID:ZMIAT_002
		By:Will
		Date:20131220
		description: No duplicated Tab page
		Remark:Coding
		*/
		-------------------------------------------------------------------	
		set @m_rows=0
		select @m_rows=count(t1.U_Tabcode)  
		from [@ZMIAT] t0 inner join [@ZMIA1] t1
				on t0.DocEntry=t1.DocEntry
		where t0.docentry=@list_of_cols_val_tab_del
		group by U_Tabcode,t0.U_Userid 
		having count(t1.U_Tabcode)>1

	    if @m_rows>1
		begin
				set @error=1
				set @error_message='(ZMIAT_002)Duplicated authorization is found in one user.'
				select @error,@error_message 
				return
		end

End

/***********************************************************************
*****************************A/P Downpayment Document*******************
***********************************************************************/
if (@object_type = '204') and (@transaction_type in ('A','U'))
Begin
   -------------------------------------------------------------------
		/*
		Coding ID:ODPO_001
		By:Will
		Date:20131223
		description: cannot add GoodsReturn for business block vendor
		Remark:Coding
		*/
		-------------------------------------------------------------------	
	    set @m_rowcount=0
		select @m_rowcount=COUNT(*)
		from odpo t0 inner join ocrd t1
		on t0.CardCode=t1.CardCode
		where u_m_bsnssblk='Y'
		and T0.docentry=@list_of_cols_val_tab_del

		if @m_rowcount>0
		begin
				set @error=1
				set @error_message='(ODPO_001)The vendor is blocked for business transactions.'
				select @error,@error_message
				return

		end
End

/***********************************************************************
*****************************Purchase Quotation*******************
***********************************************************************/
if (@object_type = '540000006') and (@transaction_type in ('A','U'))
Begin
   -------------------------------------------------------------------
		/*
		Coding ID:OPQT_001
		By:Will
		Date:20131223
		description: cannot add GoodsReturn for business block vendor
		Remark:Coding
		*/
		-------------------------------------------------------------------	
	    set @m_rowcount=0
		select @m_rowcount=COUNT(*)
		from opqt t0 inner join ocrd t1
		on t0.CardCode=t1.CardCode
		where u_m_bsnssblk='Y'

		if @m_rowcount>0
		begin
				set @error=1
				set @error_message='(OPQT_001)The vendor is blocked for business transactions.'
				select @error,@error_message
				return

		end
End
					

/***********************************************************************
*****************************Tolerance Parameters*******************
***********************************************************************/
if (@object_type = 'ZCTLC') and (@transaction_type in ('A','U'))
Begin
		/*
		Coding ID:TOL_001
		By:VINCE
		Date:20140213
		description: Document type cannot be duplicated
		Remark:Coding
		*/
		IF (SELECT COUNT(*) FROM [@ZCTLC] WHERE U_toleDoc =
					(SELECT U_toleDoc FROM [@ZCTLC] WHERE DocEntry =@list_of_cols_val_tab_del)
			)>1
		BEGIN
				set @error=1
				set @error_message='(TOL_001)Document type cannot be duplicated.'
				select @error,@error_message
				return
		END
End


/*---------------------------------------------------------------- Validations - MM End -------------------------------------------------------------------*/

-- SELECT the return values
SELECT @error, @error_message
END
