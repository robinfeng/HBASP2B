if (@object_type = 'ZMPRD') and (@transaction_type in ('A','U'))
Begin
		/*
		Coding ID:MM_006_1
		By:Robin
		Date:20140807
		Description: When PR type is direct on Purchase Request, all items entered in the PR whose item group must be direct material.
		Remark:Coding
		*/
		set @m_rowcount=0
		select @m_rowcount=COUNT(1) 
		from [@ZMPRD] T1 join [@ZMPR1] T2 on T1.DocEntry=T2.DocEntry
		join OITM T3 on T2.U_ItemCode=T3.ItemCode
		join OITB T4 on T3.ItmsGrpCod=T4.ItmsGrpCod
		where T1.docentry=@list_of_cols_val_tab_del
		and T1.U_PrType='D' and T4.U_D_DirectMat='N'
		if @m_rowcount>0
		begin
				set @error=1
				set @error_message='(PR_006_1)The PR type is direct, but found indirect item.'
				select @error,@error_message
				return
		end
		/*
		Coding ID:MM_006_2
		By:Robin
		Date:20140807
		Description: When PR type is indirect on Purchase Request, all items entered in the PR whose item group must not be direct material
		Remark:Coding
		*/
		set @m_rowcount=0
		select @m_rowcount=COUNT(1) 
		from [@ZMPRD] T1 join [@ZMPR1] T2 on T1.DocEntry=T2.DocEntry
		join OITM T3 on T2.U_ItemCode=T3.ItemCode
		join OITB T4 on T3.ItmsGrpCod=T4.ItmsGrpCod
		where T1.docentry=@list_of_cols_val_tab_del
		and T1.U_PrType='I' and T4.U_D_DirectMat='Y'
		if @m_rowcount>0
		begin
				set @error=1
				set @error_message='(PR_006_2)The PR type is indirect, but found direct item.'
				select @error,@error_message
				return
		end		
end

------ Begin Paste after POR_012 ------
/***********************************************************************
*****************************Purchase Order*****************************
***********************************************************************/
							-------------------------------------------------------
							/*
							Coding ID:POR_013
							By:Robin
							Date:20140807
							Description: When PO line is vendor consignment, PO line price must be 0
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
							and t1.U_M_Consignment='Y'
							and t1.Price>0
							and t1.LineNum=@m_currline

							if @m_rows>0
							begin
									set @error=1
									set @error_message='(POR_013)Line '+convert(varchar(20),@m_currline+1)+' is vendor consignment record, the price must be 0.'
									select @error,@error_message 

							end

							---------------------------------------------------------
							--/*
							--Coding ID:POR_014
							--By:Robin
							--Date:20140807
							--Description: All Purchase order lines have to same consignment value.
							--Remark:Coding
							--*/
							---------------------------------------------------------	
							--set @m_rowcount=0
							--set @m_rows=0
							--set @m_rows2=0
							--select @m_rowcount=COUNT(*)
							--from POR1 t1
							--where docentry=@list_of_cols_val_tab_del
							
							--select @m_rows=count(*)
							--from opor t0 inner join por1 t1
							--on t0.docentry=t1.docentry 
							--inner join oitm t4
							--on t1.itemcode =t4.ItemCode  
							--where t0.docentry=@list_of_cols_val_tab_del
							--and t1.U_M_Consignment='Y'

							--select @m_rows2=count(*)
							--from opor t0 inner join por1 t1
							--on t0.docentry=t1.docentry 
							--inner join oitm t4
							--on t1.itemcode =t4.ItemCode  
							--where t0.docentry=@list_of_cols_val_tab_del
							--and t1.U_M_Consignment='N'
							
							--if @m_rowcount>@m_rows or @m_rowcount>@m_rows2
							--begin

							--		set @error=1
							--		set @error_message='(POR_014)All Purchase order lines have to same consignment value.'
							--		select @error,@error_message 

							--end
------ End Paste after POR_012 ------

------ Add to "Validation - MM" ------
declare @m_whscode as varchar(8)
declare @m_consignment as varchar(1)
-- @m_date1
-- @m_cardcode
-- @m_itemcode

------ Begin Paste after GRPOR_004 ------
/***********************************************************************
*****************************Goods Receipt PO***************************
***********************************************************************/
IF( @object_type='20') 
BEGIN
		/*
		Coding ID:GRPOR_005
		By:Robin
		Date:20140807
		Description: GRPO for consignment PO item must be received into corresponding consignment vendor's QC warehouse;
		GRPO for non-consignment PO item must be received into corresponding QC warehouse.
		Remark:Instead of be.as Goods receipt
		*/
		DECLARE Temp_GRPOR_005_Curslr1 CURSOR FOR
	
		SELECT T0.CardCode, T1.WhsCode, T1.ItemCode, isnull(T1.U_M_Consignment,'N'), T0.DocDate, T1.LineNum
		FROM OPDN T0 join PDN1 T1 on T0.DocEntry=T1.DocEntry
		WHERE T1.docentry=@list_of_cols_val_tab_del
	
		OPEN Temp_GRPOR_005_Curslr1
	
		FETCH NEXT FROM Temp_GRPOR_005_Curslr1 INTO @m_cardcode,@m_whscode,@m_itemcode,@m_consignment,@m_date1,@lineID

		WHILE (@@FETCH_STATUS <>-1)
		BEGIN
			if @m_consignment = 'Y'
			begin
				set @m_rowcount=0
				SELECT @m_rowcount=COUNT(1)
				FROM OWHS
				WHERE WhsCode=@m_whscode
				and U_beas_lck='W' and U_M_ConsiVendor=@m_cardcode
				
				if @m_rowcount=0
				begin
						set @error=1
						set @error_message='(GRPOR_005_1)The warehouse of line '+convert(varchar(20),@lineID+1)+' is not consignment vendor QC warehouse.'
						select @error,@error_message
				end
			end
			else
			begin
				set @m_rowcount=0
				SELECT @m_rowcount=COUNT(1)
				FROM OWHS
				WHERE WhsCode=@m_whscode
				and U_beas_lck='W'
				if @m_rowcount=0
				begin
						set @error=1
						set @error_message='(GRPOR_005_2)The warehouse of line '+convert(varchar(20),@lineID+1)+' is not QC warehouse.'
						select @error,@error_message
				end				
			end
			FETCH NEXT FROM Temp_GRPOR_005_Curslr1 INTO @m_cardcode,@m_whscode,@m_itemcode,@m_consignment,@m_date1,@lineID
		END
		CLOSE Temp_GRPOR_005_Curslr1
		Deallocate Temp_GRPOR_005_Curslr1
END	
------ End Paste after GRPOR_004 ------

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
		
				-------------------------------------------------------------------
				/*
				Coding ID:GRPOR_003
				By:Will
				Date:20131203
				description: If the Item cost should great than 0, but item cost is not match this rule, User can not input it.
				Remark:Coding
				
				Update by:Robin
				Remark:If GRPO line consignment field is true, then skip the GRPOR_003 validation, meaning the cost price can be 0.
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
					and isnull(t1.U_M_Consignment,'N')='N'

					if @m_rows>0
					begin
						set @error=1
						set @error_message='(GRPOR_003)The item standard cost of :'+@m_itemcode+' is missing, please notify finance staff to modify it.'
						select @error,@error_message 
					end		