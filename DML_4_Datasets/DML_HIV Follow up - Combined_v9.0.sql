--greencard followup
SELECT P.PersonId Person_Id,
		P.ptn_pk
	,format(cast(PM.VisitDate AS DATE), 'yyyy-MM-dd') AS Encounter_Date
	,NULL Encounter_ID
	,'C' as Encounter_Type
	,CASE
		WHEN PM.VisitScheduled = '0'
			THEN 'No'
		WHEN PM.VisitScheduled = '1'
			THEN 'Yes'
		ELSE 'Yes'
		END AS Visit_scheduled
	,Visit_by = (
		SELECT TOP 1 ItemName
		FROM LookupItemView
		WHERE MasterName = 'VisitBy'
			AND ItemId = PM.VisitBy
		)
	,NULL Visit_by_other
	,Nutritional_status = (
		SELECT TOP 1 ItemDisplayName
		FROM LookupItemView
		WHERE ItemId = (
				SELECT TOP 1 ScreeningValueId
				FROM PatientScreening
				WHERE PatientMasterVisitId = PM.Id
					AND ScreeningTypeId = (
						SELECT TOP 1 MasterId
						FROM LookupItemView
						WHERE MasterName = 'NutritionStatus'
						)
				)
		)
	,Who_stage = (
		SELECT TOP 1 ItemName
		FROM LookupItemView
		WHERE MasterName = 'WHOStage'
			AND ItemId = (
				SELECT TOP 1 WHOStage
				FROM PatientWHOStage
				WHERE PatientMasterVisitId = PM.Id
				ORDER BY Id DESC
				)
		)
	,CASE WHEN pres.PresentingComplaint is null then 'No' else 'Yes' end as Presenting_complaints
	,CASE WHEN paa.Has_Known_allergies is null then 'No' else paa.Has_Known_allergies end as Has_Known_allergies
	,CASE when adve.hasAdverseEvent is null then 'No' else adve.hasAdverseEvent end as Has_adverse_drug_reaction
	,chr.Has_Chronic_illnesses_cormobidities

	,Clinical_notes = (
		SELECT TOP 1 ClinicalNotes
		FROM PatientClinicalNotes
		WHERE PatientMasterVisitId = PM.Id
		ORDER BY Id DESC
		)
	,Last_menstrual_period = format(cast((
				SELECT TOP 1 LMP
				FROM PregnancyIndicator
				WHERE PatientMasterVisitId = PM.Id
				ORDER BY Id DESC
				) AS DATE), 'yyyy-MM-dd')
	,Pregnancy_status = (
		SELECT TOP 1 DisplayName
		FROM LookupItemView
		WHERE itemid = (
				SELECT TOP 1 PregnancyStatusId
				FROM PregnancyIndicator
				WHERE PatientMasterVisitId = PM.Id
				ORDER BY Id DESC
				)
		)
	,NULL Wants_pregnancy
	,Pregnancy_outcome = (
		SELECT TOP 1 ItemName
		FROM LookupItemView
		WHERE itemid = (
				SELECT TOP 1 Outcome
				FROM Pregnancy
				WHERE PatientMasterVisitId = PM.Id
				ORDER BY ID DESC
				)
		)
	,NULL Anc_number
	,Anc_profile = CASE
		WHEN (
				SELECT TOP 1 ANCProfile
				FROM PregnancyIndicator
				WHERE PatientMasterVisitId = PM.Id
				ORDER BY Id DESC
				) = '0'
			THEN 'No'
		ELSE 'Yes'
		END
	,Expected_delivery_date = format(cast((
				SELECT TOP 1 EDD
				FROM PregnancyIndicator
				WHERE PatientMasterVisitId = PM.Id
				ORDER BY Id DESC
				) AS DATE), 'yyyy-MM-dd')
	,Gravida = (
		SELECT TOP 1 Gravidae
		FROM Pregnancy
		WHERE PatientMasterVisitId = PM.Id
		)
	,Parity_term = (
		SELECT TOP 1 Parity
		FROM Pregnancy
		WHERE PatientMasterVisitId = PM.Id
		)
	,Parity_abortion = (
		SELECT TOP 1 Parity2
		FROM Pregnancy
		WHERE PatientMasterVisitId = PM.Id
		)
	,Family_planning_status = (SELECT DisplayName FROM LookupItem WHERE Id =(select top 1 FamilyPlanningStatusId from PatientFamilyPlanning P where P.PatientMasterVisitId = PM.Id))
	,Reason_not_using_family_planning = (SELECT DisplayName FROM LookupItem WHERE Id =(select TOP 1 ReasonNotOnFPId FROM PatientFamilyPlanning P where P.PatientMasterVisitId = PM.Id))
	,NULL General_examinations_findings
	,CASE WHEN ((select COUNT(Id) from PhysicalExamination where PatientMasterVisitId = PM.Id AND ExaminationTypeId=(SELECT top 1 MasterId FROM LookupItemView WHERE MasterName = 'ReviewOfSystems'))) > 0 THEN 'Yes' ELSE 'No' END System_review_finding
	,sk.Findings AS Skin
	,sk.FindingsNotes AS Skin_finding_notes
	,ey.Findings AS Eyes
	,ey.FindingsNotes AS Eyes_Finding_notes
	,ent.Findings AS ENT
	,ent.FindingsNotes AS ENT_finding_notes
	,ch.Findings AS Chest
	,ch.FindingsNotes AS Chest_finding_notes
	,cvs.Findings AS CVS
	,cvs.FindingsNotes AS CVS_finding_notes
	,ab.Findings AS Abdomen
	,ab.FindingsNotes AS Abdomen_finding_notes
	,cns.Findings AS CNS
	,cns.FindingsNotes AS CNS_finding_notes
	,gn.Findings AS Genitourinary
	,gn.FindingsNotes AS Genitourinary_finding_notes
	,NULL Treatment_plan
	,ctx.ScoreName AS Ctx_adherence
	/*,CASE
		WHEN ctx.VisitDate IS NOT NULL
			THEN 'Yes'
		ELSE ' No'
		END AS Ctx_dispensed*/
    ,ctxph.OnCtx as Ctx_Dispensed
	,NULL AS Dapsone_adherence
	,NULL AS Dapsone_dispensed
	,adass.Morisky_forget_taking_drugs
	,adass.Morisky_careless_taking_drugs
	,adass.Morisky_stop_taking_drugs_feeling_worse
	,adass.Morisky_stop_taking_drugs_feeling_better
	,adass.Morisky_took_drugs_yesterday
	,adass.Morisky_stop_taking_drugs_symptoms_under_control
	,adass.Morisky_feel_under_pressure_on_treatment_plan
	,adass.Morisky_how_often_difficulty_remembering
	,adv.ScoreName AS Arv_adherence
	,Condom_Provided = CASE WHEN (select top 1 ItemName from LookupItemView where MasterName = 'PHDP' and ItemName = 'CD' AND ItemId = (select top 1 Phdp from PatientPHDP where PatientMasterVisitId = PM.Id AND PatientId = P.Id order by Id desc)) = 'CD' THEN 'Yes' ELSE NULL END
	,Screened_for_substance_abuse = CASE WHEN (select top 1 ItemName from LookupItemView where MasterName = 'PHDP' and ItemName = 'SA' AND ItemId = (select top 1 Phdp from PatientPHDP where PatientMasterVisitId = PM.Id AND PatientId = P.Id order by Id desc)) = 'SA' THEN 'Yes' ELSE NULL END
	,Pwp_Disclosure = CASE WHEN (select top 1 ItemName from LookupItemView where MasterName = 'PHDP' and ItemName = 'Disc' AND ItemId = (select top 1 Phdp from PatientPHDP where PatientMasterVisitId = PM.Id AND PatientId = P.Id order by Id desc)) = 'Disc' THEN 'Yes' ELSE NULL END
	,Pwp_partner_tested = CASE WHEN (select top 1 ItemName from LookupItemView where MasterName = 'PHDP' and ItemName = 'PT' AND ItemId = (select top 1 Phdp from PatientPHDP where PatientMasterVisitId = PM.Id AND PatientId = P.Id order by Id desc)) = 'PT' THEN 'Yes' ELSE NULL END
	,cacx.ScreeningValue AS Cacx_Screening
	,Screened_for_sti = CASE WHEN (select top 1 ItemName from LookupItemView where MasterName = 'PHDP' and ItemName = 'STI' AND ItemId = (select top 1 Phdp from PatientPHDP where PatientMasterVisitId = PM.Id AND PatientId = P.Id order by Id desc)) = 'STI' THEN 'Yes' ELSE NULL END
	,scp.PartnerNotification AS Sti_partner_notification
	,pcc.Stability AS Stability
	,format(cast(
	CASE 
	WHEN papp.Next_appointment_date  IS NULL
	THEN (select TOP 1
	dateadd(day,d.Duration,o.DispensedByDate) as ExpectedReturn
	from ord_PatientPharmacyOrder o
	inner join ord_Visit ov on ov.Visit_Id = o.VisitID
	inner join dtl_PatientPharmacyOrder d on d.ptn_pharmacy_pk = o.ptn_pharmacy_pk
	WHERE ov.VisitType = 4 AND d.Prophylaxis = 0 AND o.PatientMasterVisitId IS NOT NULL AND o.DispensedByDate IS NOT NULL AND o.Ptn_pk = P.ptn_pk and o.DispensedByDate = PM.VisitDate)
	WHEN papp.Next_appointment_date < (select TOP 1
	dateadd(day,d.Duration,o.DispensedByDate) as ExpectedReturn
	from ord_PatientPharmacyOrder o
	inner join ord_Visit ov on ov.Visit_Id = o.VisitID
	inner join dtl_PatientPharmacyOrder d on d.ptn_pharmacy_pk = o.ptn_pharmacy_pk
	WHERE ov.VisitType = 4 AND d.Prophylaxis = 0 AND o.PatientMasterVisitId IS NOT NULL AND o.DispensedByDate IS NOT NULL AND o.Ptn_pk = P.ptn_pk and o.DispensedByDate = PM.VisitDate)
	THEN (select TOP 1
	dateadd(day,d.Duration,o.DispensedByDate) as ExpectedReturn
	from ord_PatientPharmacyOrder o
	inner join ord_Visit ov on ov.Visit_Id = o.VisitID
	inner join dtl_PatientPharmacyOrder d on d.ptn_pharmacy_pk = o.ptn_pharmacy_pk
	WHERE ov.VisitType = 4 AND d.Prophylaxis = 0 AND o.PatientMasterVisitId IS NOT NULL AND o.DispensedByDate IS NOT NULL AND o.Ptn_pk = P.ptn_pk and o.DispensedByDate = PM.VisitDate)
	WHEN papp.Next_appointment_date > (select TOP 1
	dateadd(day,d.Duration,o.DispensedByDate) as ExpectedReturn
	from ord_PatientPharmacyOrder o
	inner join ord_Visit ov on ov.Visit_Id = o.VisitID
	inner join dtl_PatientPharmacyOrder d on d.ptn_pharmacy_pk = o.ptn_pharmacy_pk
	WHERE ov.VisitType = 4 AND d.Prophylaxis = 0 AND o.PatientMasterVisitId IS NOT NULL AND o.DispensedByDate IS NOT NULL AND o.Ptn_pk = P.ptn_pk and o.DispensedByDate = PM.VisitDate)
	THEN papp.Next_appointment_date
	ELSE papp.Next_appointment_date end
	AS DATE), 'yyyy-MM-dd') AS Next_appointment_date
	,papp.Next_appointment_reason
	,papp.Appointment_type
	,pdd.DifferentiatedCare AS Differentiated_care
	,NULL AS Voided
	,PE.createdby as Created_by
	,PE.CreateDate as Create_date
FROM PatientEncounter PE
LEFT JOIN PatientMasterVisit PM ON PM.Id = PE.PatientMasterVisitId
LEFT JOIN Patient P ON P.Id = PM.PatientId
LEFT JOIN (
	SELECT *
	FROM (
		SELECT *
			,ROW_NUMBER() OVER (
				PARTITION BY ex.PatientMasterVisitId
				,ex.PatientId ORDER BY ex.CreateDate DESC
				) rownum
		FROM (
			SELECT Id
				,PatientMasterVisitId
				,PatientId
				,ExaminationTypeId
				,(
					SELECT TOP 1 l.Name
					FROM LookupMaster l
					WHERE l.Id = e.ExaminationTypeId
					) ExaminationType
				,ExamId
				,(
					SELECT TOP 1 l.DisplayName
					FROM LookupItem l
					WHERE l.Id = e.ExamId
					) Exam
				,DeleteFlag
				,CreateBy
				,CreateDate
				,FindingId
				,(
					SELECT TOP 1 l.ItemName
					FROM LookupItemView l
					WHERE l.ItemId = e.FindingId
					) Findings
				,FindingsNotes
			FROM dbo.PhysicalExamination e
			) ex
		WHERE ex.ExaminationType = 'ReviewOfSystems'
			AND Ex.Exam = 'Skin'
		) ex
	) sk ON sk.PatientId = PE.PatientId
	AND sk.PatientMasterVisitId = PE.PatientMasterVisitId
LEFT JOIN (
	SELECT *
	FROM (
		SELECT *
			,ROW_NUMBER() OVER (
				PARTITION BY ex.PatientMasterVisitId
				,ex.PatientId ORDER BY ex.CreateDate DESC
				) rownum
		FROM (
			SELECT Id
				,PatientMasterVisitId
				,PatientId
				,ExaminationTypeId
				,(
					SELECT TOP 1 l.Name
					FROM LookupMaster l
					WHERE l.Id = e.ExaminationTypeId
					) ExaminationType
				,ExamId
				,(
					SELECT TOP 1 l.DisplayName
					FROM LookupItem l
					WHERE l.Id = e.ExamId
					) Exam
				,DeleteFlag
				,CreateBy
				,CreateDate
				,FindingId
				,(
					SELECT TOP 1 l.ItemName
					FROM LookupItemView l
					WHERE l.ItemId = e.FindingId
					) Findings
				,FindingsNotes
			FROM dbo.PhysicalExamination e
			) ex
		WHERE ex.ExaminationType = 'ReviewOfSystems'
			AND Ex.Exam = 'Eyes'
		) ex
	WHERE ex.rownum = '1'
	) ey ON ey.PatientId = PE.PatientId
	AND ey.PatientMasterVisitId = PE.PatientMasterVisitId
LEFT JOIN (
	SELECT *
	FROM (
		SELECT *
			,ROW_NUMBER() OVER (
				PARTITION BY ex.PatientMasterVisitId
				,ex.PatientId ORDER BY ex.CreateDate DESC
				) rownum
		FROM (
			SELECT Id
				,PatientMasterVisitId
				,PatientId
				,ExaminationTypeId
				,(
					SELECT TOP 1 l.Name
					FROM LookupMaster l
					WHERE l.Id = e.ExaminationTypeId
					) ExaminationType
				,ExamId
				,(
					SELECT TOP 1 l.DisplayName
					FROM LookupItem l
					WHERE l.Id = e.ExamId
					) Exam
				,DeleteFlag
				,CreateBy
				,CreateDate
				,FindingId
				,(
					SELECT TOP 1 l.ItemName
					FROM LookupItemView l
					WHERE l.ItemId = e.FindingId
					) Findings
				,FindingsNotes
			FROM dbo.PhysicalExamination e
			) ex
		WHERE ex.ExaminationType = 'ReviewOfSystems'
			AND Ex.Exam = 'ENT'
		) ex
	WHERE ex.rownum = '1'
	) ent ON ent.PatientId = PE.PatientId
	AND ent.PatientMasterVisitId = PE.PatientMasterVisitId
LEFT JOIN (
	SELECT *
	FROM (
		SELECT a.PatientId
			,a.PatientMasterVisitId
			,CASE
				WHEN a.ForgetMedicine = 0
					THEN 'No'
				WHEN a.ForgetMedicine = '1'
					THEN 'Yes'
				END AS Morisky_forget_taking_drugs
			,CASE
				WHEN a.CarelessAboutMedicine = 0
					THEN 'No'
				WHEN a.CarelessAboutMedicine = '1'
					THEN 'Yes'
				END AS Morisky_careless_taking_drugs
			,CASE
				WHEN a.FeelWorse = 0
					THEN 'No'
				WHEN a.FeelWorse = '1'
					THEN 'Yes'
				END AS Morisky_stop_taking_drugs_feeling_worse
			,CASE
				WHEN a.FeelBetter = 0
					THEN 'No'
				WHEN a.FeelBetter = '1'
					THEN 'Yes'
				END AS Morisky_stop_taking_drugs_feeling_better
			,CASE
				WHEN a.TakeMedicine = 0
					THEN 'No'
				WHEN a.TakeMedicine = '1'
					THEN 'Yes'
				END AS Morisky_took_drugs_yesterday
			,CASE
				WHEN a.StopMedicine = 0
					THEN 'No'
				WHEN a.StopMedicine = '1'
					THEN 'Yes'
				END AS Morisky_stop_taking_drugs_symptoms_under_control
			,CASE
				WHEN a.UnderPressure = 0
					THEN 'No'
				WHEN a.UnderPressure = '1'
					THEN 'Yes'
				END AS Morisky_feel_under_pressure_on_treatment_plan
			,CASE
				WHEN a.DifficultyRemembering = 0
					THEN 'Never/Rarely'
				WHEN a.DifficultyRemembering = 0.25
					THEN 'Once in a while'
				WHEN a.DifficultyRemembering = 0.5
					THEN 'Sometimes'
				WHEN a.DifficultyRemembering = 0.75
					THEN 'Usually'
				WHEN a.DifficultyRemembering = 1
					THEN 'All the Time'
				END AS Morisky_how_often_difficulty_remembering
			,ROW_NUMBER() OVER (
				PARTITION BY a.PatientId
				,a.PatientMasterVisitId ORDER BY a.Id DESC
				) rownum
		FROM AdherenceAssessment a
		WHERE Deleteflag = 0
		) ad
	WHERE ad.rownum = '1'
	) adass ON adass.PatientId = PE.PatientId
	AND adass.PatientMasterVisitId = PE.PatientMasterVisitId
LEFT JOIN (
	SELECT *
	FROM (
		SELECT *
			,ROW_NUMBER() OVER (
				PARTITION BY ex.PatientMasterVisitId
				,ex.PatientId ORDER BY ex.CreateDate DESC
				) rownum
		FROM (
			SELECT Id
				,PatientMasterVisitId
				,PatientId
				,ExaminationTypeId
				,(
					SELECT TOP 1 l.Name
					FROM LookupMaster l
					WHERE l.Id = e.ExaminationTypeId
					) ExaminationType
				,ExamId
				,(
					SELECT TOP 1 l.DisplayName
					FROM LookupItem l
					WHERE l.Id = e.ExamId
					) Exam
				,DeleteFlag
				,CreateBy
				,CreateDate
				,FindingId
				,(
					SELECT TOP 1 l.ItemName
					FROM LookupItemView l
					WHERE l.ItemId = e.FindingId
					) Findings
				,FindingsNotes
			FROM dbo.PhysicalExamination e
			) ex
		WHERE ex.ExaminationType = 'ReviewOfSystems'
			AND Ex.Exam = 'Chest'
		) ex
	WHERE ex.rownum = '1'
	) ch ON ch.PatientId = PE.PatientId
	AND ch.PatientMasterVisitId = PE.PatientMasterVisitId
LEFT JOIN (
	SELECT *
	FROM (
		SELECT *
			,ROW_NUMBER() OVER (
				PARTITION BY ex.PatientMasterVisitId
				,ex.PatientId ORDER BY ex.CreateDate DESC
				) rownum
		FROM (
			SELECT Id
				,PatientMasterVisitId
				,PatientId
				,ExaminationTypeId
				,(
					SELECT TOP 1 l.Name
					FROM LookupMaster l
					WHERE l.Id = e.ExaminationTypeId
					) ExaminationType
				,ExamId
				,(
					SELECT TOP 1 l.DisplayName
					FROM LookupItem l
					WHERE l.Id = e.ExamId
					) Exam
				,DeleteFlag
				,CreateBy
				,CreateDate
				,FindingId
				,(
					SELECT TOP 1 l.ItemName
					FROM LookupItemView l
					WHERE l.ItemId = e.FindingId
					) Findings
				,FindingsNotes
			FROM dbo.PhysicalExamination e
			) ex
		WHERE ex.ExaminationType = 'ReviewOfSystems'
			AND Ex.Exam = 'CVS'
		) ex
	WHERE ex.rownum = '1'
	) cvs ON cvs.PatientId = PE.PatientId
	AND cvs.PatientMasterVisitId = PE.PatientMasterVisitId
LEFT JOIN (
	SELECT *
	FROM (
		SELECT *
			,ROW_NUMBER() OVER (
				PARTITION BY ex.PatientMasterVisitId
				,ex.PatientId ORDER BY ex.CreateDate DESC
				) rownum
		FROM (
			SELECT Id
				,PatientMasterVisitId
				,PatientId
				,ExaminationTypeId
				,(
					SELECT TOP 1 l.Name
					FROM LookupMaster l
					WHERE l.Id = e.ExaminationTypeId
					) ExaminationType
				,ExamId
				,(
					SELECT TOP 1 l.DisplayName
					FROM LookupItem l
					WHERE l.Id = e.ExamId
					) Exam
				,DeleteFlag
				,CreateBy
				,CreateDate
				,FindingId
				,(
					SELECT TOP 1 l.ItemName
					FROM LookupItemView l
					WHERE l.ItemId = e.FindingId
					) Findings
				,FindingsNotes
			FROM dbo.PhysicalExamination e
			) ex
		WHERE ex.ExaminationType = 'ReviewOfSystems'
			AND Ex.Exam = 'Abdomen'
		) ex
	WHERE ex.rownum = '1'
	) ab ON ab.PatientId = PE.PatientId
	AND ab.PatientMasterVisitId = PE.PatientMasterVisitId
LEFT JOIN (
	SELECT *
	FROM (
		SELECT *
			,ROW_NUMBER() OVER (
				PARTITION BY ex.PatientMasterVisitId
				,ex.PatientId ORDER BY ex.CreateDate DESC
				) rownum
		FROM (
			SELECT Id
				,PatientMasterVisitId
				,PatientId
				,ExaminationTypeId
				,(
					SELECT TOP 1 l.Name
					FROM LookupMaster l
					WHERE l.Id = e.ExaminationTypeId
					) ExaminationType
				,ExamId
				,(
					SELECT TOP 1 l.DisplayName
					FROM LookupItem l
					WHERE l.Id = e.ExamId
					) Exam
				,DeleteFlag
				,CreateBy
				,CreateDate
				,FindingId
				,(
					SELECT TOP 1 l.ItemName
					FROM LookupItemView l
					WHERE l.ItemId = e.FindingId
					) Findings
				,FindingsNotes
			FROM dbo.PhysicalExamination e
			) ex
		WHERE ex.ExaminationType = 'ReviewOfSystems'
			AND Ex.Exam = 'CNS'
		) ex
	WHERE ex.rownum = '1'
	) cns ON cns.PatientId = PE.PatientId
	AND cns.PatientMasterVisitId = PE.PatientMasterVisitId
LEFT JOIN (
	SELECT *
	FROM (
		SELECT *
			,ROW_NUMBER() OVER (
				PARTITION BY ex.PatientMasterVisitId
				,ex.PatientId ORDER BY ex.CreateDate DESC
				) rownum
		FROM (
			SELECT Id
				,PatientMasterVisitId
				,PatientId
				,ExaminationTypeId
				,(
					SELECT TOP 1 l.Name
					FROM LookupMaster l
					WHERE l.Id = e.ExaminationTypeId
					) ExaminationType
				,ExamId
				,(
					SELECT TOP 1 l.DisplayName
					FROM LookupItem l
					WHERE l.Id = e.ExamId
					) Exam
				,DeleteFlag
				,CreateBy
				,CreateDate
				,FindingId
				,(
					SELECT TOP 1 l.ItemName
					FROM LookupItemView l
					WHERE l.ItemId = e.FindingId
					) Findings
				,FindingsNotes
			FROM dbo.PhysicalExamination e
			) ex
		WHERE ex.ExaminationType = 'ReviewOfSystems'
			AND Ex.Exam LIKE 'Genito-urinary'
		) ex
	WHERE ex.rownum = '1'
	) gn ON gn.PatientId = pe.PatientId
	AND gn.PatientMasterVisitId = pe.PatientMasterVisitId
LEFT JOIN (
	SELECT pa.PatientId
		,pa.PatientMasterVisitId
		,pa.AppointmentReason AS Next_appointment_reason
		,pa.Appointment_type
		,pa.AppointmentDate AS Next_appointment_date
	FROM (
		SELECT pa.PatientId
			,pa.PatientMasterVisitId
			,pa.AppointmentDate
			,pa.DifferentiatedCareId
			,pa.ReasonId
			,li.DisplayName AS AppointmentReason
			,ROW_NUMBER() OVER (
				PARTITION BY pa.PatientId
				,pa.PatientMasterVisitId ORDER BY pa.CreateDate DESC
				) rownum
			,lt.DisplayName AS Appointment_type
			,pa.DeleteFlag
			,pa.ServiceAreaId
			,pa.CreateDate
		FROM PatientAppointment pa
		INNER JOIN LookupItem li ON li.Id = pa.ReasonId
		INNER JOIN LookupItem lt ON lt.Id = pa.DifferentiatedCareId
		WHERE pa.DeleteFlag IS NULL
			OR pa.DeleteFlag = 0
		) pa
	WHERE pa.rownum = 1
	) papp ON papp.PatientId = pe.PatientId
	AND papp.PatientMasterVisitId = pe.PatientMasterVisitId
LEFT JOIN (
	SELECT pad.PatientId
		,pad.PatientMasterVisitId
		,'Yes' AS DifferentiatedCare
	FROM PatientArtDistribution pad
	WHERE DeleteFlag = 0
		OR DeleteFlag IS NULL
	) pdd ON pdd.PatientId = pe.PatientId
	AND pdd.PatientMasterVisitId = pe.PatientMasterVisitId
LEFT JOIN (
	SELECT *
	FROM (
		SELECT pc.PatientId
			,pc.PatientMasterVisitId
			,CASE
				WHEN pc.Categorization = 2
					THEN 'Unstable'
				WHEN pc.Categorization = 1
					THEN 'Stable'
				END AS Stability
			,ROW_NUMBER() OVER (
				PARTITION BY pc.PatientId
				,pc.PatientMasterVisitId ORDER BY pc.id DESC
				) rownum
		FROM PatientCategorization pc
		) pc
	WHERE pc.rownum = 1
	) pcc ON pcc.PatientId = pe.PatientId
	AND pcc.PatientMasterVisitId = pe.PatientMasterVisitId
LEFT JOIN (
	SELECT scp.PatientId
		,scp.PatientMasterVisitId
		,scp.Name AS PartnerNotification
	FROM (
		SELECT sc.PatientId
			,sc.PatientMasterVisitId
			,sc.ScreeningTypeId
			,sc.ScreeningValueId
			,li.Name
			,ROW_NUMBER() OVER (
				PARTITION BY sc.PatientId
				,sc.PatientMasterVisitid ORDER BY sc.Id DESC
				) rownum
		FROM PatientScreening sc
		INNER JOIN LookupMaster lm ON lm.Id = sc.ScreeningTypeId
			AND lm.Name = 'STIPartnerNotification'
		INNER JOIN LookupItem li ON li.Id = sc.ScreeningValueId
		WHERE sc.DeleteFlag IS NULL
			OR sc.DeleteFlag = 0
		) scp
	WHERE scp.rownum = '1'
	) scp ON scp.PatientId = pe.PatientId
	AND scp.PatientMasterVisitId = pe.PatientMasterVisitId
LEFT JOIN (
	SELECT *
	FROM (
		SELECT psc.PatientId
			,psc.PatientMasterVisitId
			,lm.[DisplayName] AS ScreeningType
			,psc.DeleteFlag
			,psc.VisitDate
			,psc.ScreeningDate
			,psc.CreateDate
			,lt.DisplayName AS ScreeningValue
			,ROW_NUMBER() OVER (
				PARTITION BY psc.PatientId
				,psc.PatientMasterVisitId ORDER BY psc.CreateDate DESC
				) rownum
		FROM PatientScreening psc
		INNER JOIN LookupMaster lm ON lm.[Id] = psc.ScreeningTypeId
		INNER JOIN LookupItem lt ON lt.Id = psc.ScreeningValueId
		WHERE lm.[Name] = 'CacxScreening'
			AND (
				psc.DeleteFlag IS NULL
				OR psc.DeleteFlag = 0
				)
		) psc
	WHERE psc.rownum = '1'
	) cacx ON cacx.PatientId = pe.PatientId
	AND cacx.PatientMasterVisitId = pe.PatientMasterVisitId
---PresentingComplaints
left join (select PatientId,PatientMasterVisitId,PresentingComplaintsId,PresentingComplaint from (select  PatientId,PatientMasterVisitId,PresentingComplaintsId,pres.deleteFlag,CreatedBy,CreatedDate,lt.DisplayName as PresentingComplaint,
ROW_NUMBER() OVER(partition by PatientId,PatientMasterVisitId order by CreatedDate desc)rownum
 from PresentingComplaints pres
 inner join LookupItem lt on lt.Id=pres.PresentingComplaintsId
 where pres.deleteFlag is null or pres.deleteFlag=0
 ) pre where rownum='1')pres on pres.PatientId=pe.PatientId and pres.PatientMasterVisitId=pe.PatientMasterVisitId

 ---
 left join(select * from (select PatientId,PatientMasterVisitId,OnsetDate ,AllergenName as Allergies_causative_agents,ReactionName as Allergies_reactions,'Yes' as Has_Known_allergies,
SeverityName as Allergies_severity,ROW_NUMBER() OVER(partition by PatientId,PatientMasterVisitId order by  PatientMasterVisitId desc)rownum

 from PatientAllergyView
where DeleteFlag is null or DeleteFlag=0
 )pav where pav.rownum =1)paa on paa.PatientId=pe.PatientId and paa.PatientMasterVisitId =pe.PatientMasterVisitId
 ----
 
left join(select ad.PatientId,ad.PatientMasterVisitId,ad.hasAdverseEvent from (select PatientId,PatientMasterVisitId,EventName,EventCause,Severity,'Yes' hasAdverseEvent ,DeleteFlag,ROW_NUMBER() OVER(partition by PatientId,PatientMasterVisitId order by  PatientMasterVisitId desc)rownum from AdverseEvent
)ad where ad.rownum=1)adve on adve.PatientId=pe.PatientId and adve.PatientMasterVisitId=pe.PatientMasterVisitId


 ---
 left join (select * from (select PatientId,PatientMasterVisitId ,ChronicIllness as Chronic_illnesses_name,
OnsetDate as Chronic_illnesses_onset_date ,'Yes' as Has_Chronic_illnesses_cormobidities,
ROW_NUMBER() OVER(partition by PatientId,PatientMasterVisitId order by  PatientMasterVisitId desc)rownum

 from PatientChronicIllnessView
 where DeleteFlag is null or DeleteFlag=0
 )pav where pav.rownum =1
)chr on chr.PatientId =pe.PatientId and chr.PatientMasterVisitId =pe.PatientMasterVisitId

 ----
LEFT JOIN (
	SELECT *
	FROM (
		SELECT ao.Id
			,ao.PatientId
			,ao.PatientMasterVisitId
			,ao.Score
			,ROW_NUMBER() OVER (
				PARTITION BY ao.PatientId
				,ao.PatientMasterVisitId ORDER BY ao.CreateDate DESC
				) rownum
			,ao.AdherenceType
			,lm.[Name] AS AdherenceTypeName
			,lti.DisplayName AS ScoreName
			,ao.DeleteFlag
			,pmv.VisitDate
		FROM AdherenceOutcome ao
		INNER JOIN LookupMaster lm ON lm.Id = ao.AdherenceType
		INNER JOIN LookupItem lti ON lti.Id = ao.Score
		INNER JOIN PatientMasterVisit pmv ON pmv.Id = ao.PatientMasterVisitId
		WHERE lm.[Name] = 'CTXAdherence'
			AND (
				ao.DeleteFlag IS NULL
				OR ao.DeleteFlag = 0
				)
		) adv
	WHERE adv.rownum = '1'
	) ctx ON ctx.PatientId = pe.PatientId
	AND ctx.PatientMasterVisitId = pe.PatientMasterVisitId

left join(select ctx.PersonId,ctx.OnCtx,ctx.DispensedByDate,ctx.Drug_name,ctx.Ptn_pk from(select 
P.PersonId,
OPPO.Ptn_pk,
OPPO.OrderedByDate,
NULL Encounter_ID,
RM.RegimenType,
OPPO.PatientMasterVisitId,
CASE WHEN (select top 1 DrugName from VW_Drug where DrugName like '%Sulfa/TMX-Cotrimoxazole%' AND Drug_pk = DPPO.Drug_Pk) IS NOT NULL THEN 'Yes'
 WHEN (select top 1 DrugName from VW_Drug where DrugName like '%Sulfa%tmx%' AND Drug_pk = DPPO.Drug_Pk) IS NOT NULL THEN 'Yes'
 WHEN (select  top 1 DrugName from VW_Drug where DrugName like '%co%tri%' AND Drug_pk = DPPO.Drug_Pk) IS NOT NULL THEN 'Yes'
 WHEN (select top 1 DrugName from VW_Drug where DrugName like '%dapson%' AND Drug_pk = DPPO.Drug_Pk) IS NOT NULL THEN 'Yes'
 else NULL end as OnCtx,
(select top 1 DrugName from VW_Drug where Drug_pk = DPPO.Drug_Pk) Drug_name,
Dose = (1),
Unit = (select StrengthName from mst_Strength where StrengthId = (SELECT top 1 StrengthId FROM Lnk_DrugStrength where DrugId=DPPO.Drug_Pk)),
Frequency = (select top 1 Name from mst_Frequency where FrequencyID = DPPO.FrequencyID),
Duration = (DPPO.Duration),
Duration_units  = ('days'),  
Prescription_provider = (Select UserFirstName + ' '+ UserLastName from mst_User where UserID = OPPO.UserID),
Dispensing_provider = (Select UserFirstName + ' '+ UserLastName from mst_User where UserID = DPPO.UserID),
OPPO.DispensedByDate
from ord_PatientPharmacyOrder OPPO
LEFT JOIN dtl_RegimenMap RM ON RM.OrderID = OPPO.ptn_pharmacy_pk
LEFT JOIN dtl_PatientPharmacyOrder DPPO ON OPPO.ptn_pharmacy_pk = DPPO.ptn_pharmacy_pk
LEFT JOIN Patient P ON P.ptn_pk = OPPO.Ptn_pk
)ctx where ctx.OnCtx='Yes')ctxph on ctxph.Ptn_pk=p.ptn_pk 
and datediff(day, ctxph.DispensedByDate, PM.VisitDate) = 0
--and format(CAST(ctxph.DispensedByDate as date),'yyyy-mm-dd')=format(cast(PM.VisitDate AS DATE), 'yyyy-MM-dd') or ctxph
LEFT JOIN (
	SELECT *
	FROM (
		SELECT ao.Id
			,ao.PatientId
			,ao.PatientMasterVisitId
			,ao.Score
			,ROW_NUMBER() OVER (
				PARTITION BY ao.PatientId
				,ao.PatientMasterVisitId ORDER BY ao.CreateDate DESC
				) rownum
			,ao.AdherenceType
			,lm.[Name] AS AdherenceTypeName
			,lti.DisplayName AS ScoreName
			,ao.DeleteFlag
			,pmv.VisitDate
		FROM AdherenceOutcome ao
		INNER JOIN LookupMaster lm ON lm.Id = ao.AdherenceType
		INNER JOIN LookupItem lti ON lti.Id = ao.Score
		INNER JOIN PatientMasterVisit pmv ON pmv.Id = ao.PatientMasterVisitId
		WHERE lm.[Name] = 'ARVAdherence'
			AND (
				ao.DeleteFlag IS NULL
				OR ao.DeleteFlag = 0
				)
		) adv
	WHERE adv.rownum = '1'
	) adv ON adv.PatientId = pe.PatientId
	AND adv.PatientMasterVisitId = pe.PatientMasterVisitId
WHERE PE.EncounterTypeId = (
		SELECT ItemId
		FROM LookupItemView
		WHERE MasterName = 'EncounterType'
			AND ItemName = 'ccc-encounter'
		)
		UNION
--Greencard pharmacy
SELECT 

P.PersonId Person_Id,
P.Ptn_Pk,
format(cast(coalesce(PD.DispensedByDate,PD.OrderedByDate,PD.VisitDate) AS DATE), 'yyyy-MM-dd') AS Encounter_Date,
NULL AS Encounter_ID,
'P' as Encounter_Type,
NULL AS Visit_scheduled,
NULL AS Visit_by,
NULL Visit_by_other,
NULL AS Nutritional_status,
NULL AS Who_stage,
NULL Presenting_complaints,
NULL Has_Known_allergies,
NULL Has_adverse_drug_reaction,
NULL Has_Chronic_illnesses_cormobidities,
NULL AS Clinical_notes,
NULL as Last_menstrual_period,
NULL as Pregnancy_status,
NULL as Wants_pregnancy,
NULL as Pregnancy_outcome,
NULL as Anc_number,
NULL AS Anc_profile,
NULL  as Expected_delivery_date,
NULL as Gravida,
NULL as Parity_term,
NULL as Parity_abortion,
NULL as Family_planning_status,
NULL Reason_not_using_family_planning,
NULL as General_examinations_findings,
NULL as System_review_finding,
NULL as Skin,
NULL as Skin_finding_notes,
NULL as Eyes,
NULL as Eyes_Finding_notes,
NULL as ENT,
NULL as ENT_finding_notes,
NULL as Chest,
NULL as Chest_finding_notes,
NULL as CVS,
NULL as CVS_finding_notes,
NULL as Abdomen,
NULL as Abdomen_finding_notes,
NULL as CNS,
NULL as CNS_finding_notes,
NULL as Genitourinary,
NULL as Genitourinary_finding_notes,
NULL as Treatment_plan,
NULL as Ctx_adherence,
PD.ctxDispensed  as Ctx_dispensed,
NULL as Dapsone_adherence,
NULL as Dapsone_dispensed,
NULL Morisky_forget_taking_drugs,
NULL Morisky_careless_taking_drugs,
NULL Morisky_stop_taking_drugs_feeling_worse,
NULL Morisky_stop_taking_drugs_feeling_better,
NULL Morisky_took_drugs_yesterday,
NULL Morisky_stop_taking_drugs_symptoms_under_control,
NULL Morisky_feel_under_pressure_on_treatment_plan,
NULL Morisky_how_often_difficulty_remembering,
NULL as Arv_adherence,
NULL Condom_Provided,
NULL Screened_for_substance_abuse,
NULL Pwp_Disclosure,
NULL Pwp_partner_tested,
NULL as Cacx_Screening,
NULL Screened_for_sti,
NULL as Sti_partner_notification,
NULL as Stability,
format(cast(PD.ExpectedReturn AS DATE), 'yyyy-MM-dd') AS Next_appointment_date,
NULL Next_appointment_reason,
NULL Appointment_type,
NULL as Differentiated_care,
NULL as Voided
,PD.Created_by as Created_by
,PD.Create_date as Create_date
FROM(SELECT 
dateadd(day, ro.Duration, o.DispensedByDate) AS ExpectedReturn, 
PM.PatientId,
PM.VisitDate,
o.DispensedByDate,
o.OrderedByDate
,o.UserID as Created_by
,o.CreateDate as Create_date,
cotph.OnCtx as ctxDispensed
FROM ord_PatientPharmacyOrder o
INNER JOIN dtl_PatientPharmacyOrder ro on ro.ptn_pharmacy_pk = o.ptn_pharmacy_pk
LEFT JOIN PatientMasterVisit PM on PM.Id = o.PatientMasterVisitId
LEFT JOIN PatientEncounter PE ON PE.PatientMasterVisitId = PM.Id
left join(select ctx.PersonId,ctx.OnCtx,ctx.DispensedByDate,ctx.Drug_name,ctx.Ptn_pk,ctx.ptn_pharmacy_pk from(select 
P.PersonId,
OPPO.Ptn_pk,
OPPO.ptn_pharmacy_pk,
OPPO.OrderedByDate,
NULL Encounter_ID,
RM.RegimenType,
OPPO.PatientMasterVisitId,

CASE WHEN (select top 1 DrugName from VW_Drug where DrugName like '%Sulfa/TMX-Cotrimoxazole%' AND Drug_pk = DPPO.Drug_Pk) IS NOT NULL THEN 'Yes'
 WHEN (select top 1 DrugName from VW_Drug where DrugName like '%Sulfa%tmx%' AND Drug_pk = DPPO.Drug_Pk) IS NOT NULL THEN 'Yes'
 WHEN (select top 1 DrugName from VW_Drug where DrugName like '%co%tri%' AND Drug_pk = DPPO.Drug_Pk) IS NOT NULL THEN 'Yes'
 WHEN (select top 1 DrugName from VW_Drug where DrugName like '%dapson%' AND Drug_pk = DPPO.Drug_Pk) IS NOT NULL THEN 'Yes'
 else NULL end as OnCtx,
(select top 1 DrugName from VW_Drug where Drug_pk = DPPO.Drug_Pk) Drug_name,
Dose = (1),
Unit = (select StrengthName from mst_Strength where StrengthId = (SELECT top 1 StrengthId FROM Lnk_DrugStrength where DrugId=DPPO.Drug_Pk)),
Frequency = (select top 1 Name from mst_Frequency where FrequencyID = DPPO.FrequencyID),
Duration = (DPPO.Duration),
Duration_units  = ('days'),  
Prescription_provider = (Select UserFirstName + ' '+ UserLastName from mst_User where UserID = OPPO.UserID),
Dispensing_provider = (Select UserFirstName + ' '+ UserLastName from mst_User where UserID = DPPO.UserID),
OPPO.DispensedByDate
from ord_PatientPharmacyOrder OPPO
LEFT JOIN dtl_RegimenMap RM ON RM.OrderID = OPPO.ptn_pharmacy_pk
LEFT JOIN dtl_PatientPharmacyOrder DPPO ON OPPO.ptn_pharmacy_pk = DPPO.ptn_pharmacy_pk
LEFT JOIN Patient P ON P.ptn_pk = OPPO.Ptn_pk
)ctx where ctx.OnCtx='Yes')cotph on cotph.Ptn_pharmacy_pk=ro.ptn_pharmacy_pk

WHERE o.DispensedByDate is not null AND ro.Prophylaxis = 0  AND o.ProgID IN (SELECT ID FROM mst_Decode WHERE Name IN ('ART', 'PMTCT')) AND o.PatientMasterVisitId IS NOT NULL AND PE.EncounterTypeId = (SELECT ItemId FROM LookupItemView WHERE MasterName = 'EncounterType' AND ItemName = 'Pharmacy-encounter')) PD
LEFT JOIN (
SELECT 
PM.VisitDate,
PM.PatientId

FROM PatientEncounter PE
LEFT JOIN PatientMasterVisit PM ON PM.Id = PE.PatientMasterVisitId
LEFT JOIN Patient P ON P.Id = PM.PatientId
WHERE PE.EncounterTypeId = (SELECT ItemId FROM LookupItemView WHERE MasterName = 'EncounterType' AND ItemName = 'ccc-encounter')
) PDR ON PDR.PatientId = PD.PatientId AND format(cast(PDR.VisitDate AS DATE), 'yyyy-MM-dd') = format(cast(PD.VisitDate AS DATE), 'yyyy-MM-dd')
INNER JOIN Patient P ON P.Id = PD.PatientId
WHERE PDR.VisitDate IS NULL

UNION
--BLUECARD FOLLOWUP
SELECT
P.PersonId Person_Id,
MP.Ptn_Pk,
format(cast(OV.VisitDate AS DATE), 'yyyy-MM-dd') AS Encounter_Date,
NULL AS Encounter_ID,
'C' as Encounter_Type,
CASE WHEN ISNULL(PAE.Scheduled, '0') = '0' THEN 'No' WHEN PAE.Scheduled = '1' THEN 'Yes' END AS Visit_scheduled,
CASE (select Name from mst_bluedecode where codeid=8 and (DeleteFlag = 0 or DeleteFlag IS NULL) and ID = OV.TypeofVisit)
WHEN 'SF - Self' THEN 'S' WHEN 'TS - Treatment Supporter' THEN 'TS' ELSE 'S' END AS Visit_by,
NULL Visit_by_other,
NULL AS Nutritional_status,
CASE(select Name from mst_Decode where CodeID = 22  and (DeleteFlag = 0 or DeleteFlag IS NULL) AND ID = PS.WHOStage)
WHEN '1' THEN 'Stage1' WHEN '2' THEN 'Stage2' WHEN '3' THEN 'Stage3' WHEN '4' THEN 'Stage4' WHEN 'N/A' THEN NULL WHEN 'T1' THEN 'Stage1' WHEN 'T2' THEN 'Stage2' WHEN 'T3' THEN 'Stage3' WHEN 'T4' THEN 'Stage4' ELSE NULL END AS Who_stage,
NULL Presenting_complaints,
NULL Has_Known_allergies,
NULL Has_adverse_drug_reaction,
NULL Has_Chronic_illnesses_cormobidities,
NULL AS Clinical_notes,
NULL as Last_menstrual_period,
NULL as Pregnancy_status,
CASE WHEN (select Name from mst_bluedeCode where CodeID = 15 and (DeleteFlag = 0 or DeleteFlag IS NULL) AND ID = PC.FamilyPlanningStatus) = 'Wants Family Planning' THEN 'Yes' ELSE 'No' END as Wants_pregnancy,
NULL as Pregnancy_outcome,
NULL as Anc_number,
NULL AS Anc_profile,
NULL  as Expected_delivery_date,
NULL as Gravida,
NULL as Parity_term,
NULL as Parity_abortion,
(select Name from mst_bluedeCode where CodeID = 15 and (DeleteFlag = 0 or DeleteFlag IS NULL) AND ID = PC.FamilyPlanningStatus) as Family_planning_status,
NULL Reason_not_using_family_planning,
NULL as General_examinations_findings,
NULL as System_review_finding,
NULL as Skin,
NULL as Skin_finding_notes,
NULL as Eyes,
NULL as Eyes_Finding_notes,
NULL as ENT,
NULL as ENT_finding_notes,
NULL as Chest,
NULL as Chest_finding_notes,
NULL as CVS,
NULL as CVS_finding_notes,
NULL as Abdomen,
NULL as Abdomen_finding_notes,
NULL as CNS,
NULL as CNS_finding_notes,
NULL as Genitourinary,
NULL as Genitourinary_finding_notes,
NULL as Treatment_plan,
NULL as Ctx_adherence,
cotph.OnCtx as Ctx_dispensed,
NULL as Dapsone_adherence,
NULL as Dapsone_dispensed,
NULL Morisky_forget_taking_drugs,
NULL Morisky_careless_taking_drugs,
NULL Morisky_stop_taking_drugs_feeling_worse,
NULL Morisky_stop_taking_drugs_feeling_better,
NULL Morisky_took_drugs_yesterday,
NULL Morisky_stop_taking_drugs_symptoms_under_control,
NULL Morisky_feel_under_pressure_on_treatment_plan,
NULL Morisky_how_often_difficulty_remembering,
NULL as Arv_adherence,
NULL Condom_Provided,
NULL Screened_for_substance_abuse,
NULL Pwp_Disclosure,
NULL Pwp_partner_tested,
NULL as Cacx_Screening,
NULL Screened_for_sti,
NULL as Sti_partner_notification,
NULL as Stability,
format(cast(CASE 
WHEN bapp.AppDate IS NULL 
	THEN	(select TOP 1 
		dateadd(day,d.Duration,o.DispensedByDate) as ExpectedReturn
		from ord_PatientPharmacyOrder o
		inner join ord_Visit kth on kth.Visit_Id = o.VisitID
		inner join dtl_PatientPharmacyOrder d on d.ptn_pharmacy_pk = o.ptn_pharmacy_pk
		WHERE kth.VisitType = 4 AND d.Prophylaxis = 0  AND o.ProgID IN (SELECT ID FROM mst_Decode WHERE Name IN ('ART', 'PMTCT')) AND o.DispensedByDate IS NOT NULL AND kth.VisitDate = OV.VisitDate and kth.Ptn_pk = OV.Ptn_Pk AND PatientMasterVisitId IS NULL) 
WHEN (select TOP 1 
	dateadd(day,d.Duration,o.DispensedByDate) as ExpectedReturn
	from ord_PatientPharmacyOrder o
	inner join ord_Visit kth on kth.Visit_Id = o.VisitID
	inner join dtl_PatientPharmacyOrder d on d.ptn_pharmacy_pk = o.ptn_pharmacy_pk
	WHERE kth.VisitType = 4 AND d.Prophylaxis = 0  AND o.ProgID IN (SELECT ID FROM mst_Decode WHERE Name IN ('ART', 'PMTCT')) AND o.DispensedByDate IS NOT NULL AND kth.VisitDate = OV.VisitDate and kth.Ptn_pk = OV.Ptn_Pk AND PatientMasterVisitId IS NULL)  > bapp.AppDate 
THEN (select TOP 1 
	dateadd(day,d.Duration,o.DispensedByDate) as ExpectedReturn
	from ord_PatientPharmacyOrder o
	inner join ord_Visit kth on kth.Visit_Id = o.VisitID
	inner join dtl_PatientPharmacyOrder d on d.ptn_pharmacy_pk = o.ptn_pharmacy_pk
	WHERE kth.VisitType = 4 AND d.Prophylaxis = 0  AND o.ProgID IN (SELECT ID FROM mst_Decode WHERE Name IN ('ART', 'PMTCT')) AND o.DispensedByDate IS NOT NULL AND kth.VisitDate = OV.VisitDate and kth.Ptn_pk = OV.Ptn_Pk AND PatientMasterVisitId IS NULL) 
WHEN bapp.AppDate > (select TOP 1 
	dateadd(day,d.Duration,o.DispensedByDate) as ExpectedReturn
	from ord_PatientPharmacyOrder o
	inner join ord_Visit kth on kth.Visit_Id = o.VisitID
	inner join dtl_PatientPharmacyOrder d on d.ptn_pharmacy_pk = o.ptn_pharmacy_pk
	WHERE kth.VisitType = 4 AND d.Prophylaxis = 0  AND o.ProgID IN (SELECT ID FROM mst_Decode WHERE Name IN ('ART', 'PMTCT')) AND o.DispensedByDate IS NOT NULL AND kth.VisitDate = OV.VisitDate and kth.Ptn_pk = OV.Ptn_Pk AND PatientMasterVisitId IS NULL) 
THEN bapp.AppDate 
ELSE bapp.AppDate END AS DATE), 'yyyy-MM-dd') AS Next_appointment_date,
NULL Next_appointment_reason,
NULL Appointment_type,
NULL as Differentiated_care,
NULL as Voided
,OV.UserID as Created_by
,OV.CreateDate as Create_date
FROM ord_Visit OV
LEFT JOIN mst_Patient MP ON MP.Ptn_Pk = OV.Ptn_Pk
LEFT JOIN Patient P ON P.ptn_pk = MP.Ptn_Pk
LEFT JOIN dtl_PatientARTEncounter PAE ON PAE.Visit_Id = OV.Visit_Id
LEFT JOIN dtl_PatientStage PS ON PS.Visit_Pk = OV.Visit_Id
LEFT JOIN dtl_PatientDisease PDS ON PDS.Visit_Pk = OV.Visit_Id AND MP.Ptn_Pk = PDS.Ptn_Pk
LEFT JOIN dtl_patientCounseling PC ON PC.Visit_pk = OV.Visit_Id AND PC.Ptn_pk = MP.Ptn_Pk
left join(select ctx.PersonId,ctx.OnCtx,ctx.DispensedByDate,ctx.Drug_name,ctx.Ptn_pk,ctx.ptn_pharmacy_pk from(select 
P.PersonId,
OPPO.Ptn_pk,
OPPO.ptn_pharmacy_pk,
OPPO.OrderedByDate,
NULL Encounter_ID,
RM.RegimenType,
OPPO.PatientMasterVisitId,

CASE WHEN (select top 1 DrugName from VW_Drug where DrugName like '%Sulfa/TMX-Cotrimoxazole%' AND Drug_pk = DPPO.Drug_Pk) IS NOT NULL THEN 'Yes'
 WHEN (select top 1 DrugName from VW_Drug where DrugName like '%Sulfa%tmx%' AND Drug_pk = DPPO.Drug_Pk) IS NOT NULL THEN 'Yes'
 WHEN (select top 1 DrugName from VW_Drug where DrugName like '%co%tri%' AND Drug_pk = DPPO.Drug_Pk) IS NOT NULL THEN 'Yes'
 WHEN (select top 1 DrugName from VW_Drug where DrugName like '%dapson%' AND Drug_pk = DPPO.Drug_Pk) IS NOT NULL THEN 'Yes'
 else NULL end as OnCtx,
(select top 1 DrugName from VW_Drug where Drug_pk = DPPO.Drug_Pk) Drug_name,
Dose = (1),
Unit = (select StrengthName from mst_Strength where StrengthId = (SELECT top 1 StrengthId FROM Lnk_DrugStrength where DrugId=DPPO.Drug_Pk)),
Frequency = (select top 1 Name from mst_Frequency where FrequencyID = DPPO.FrequencyID),
Duration = (DPPO.Duration),
Duration_units  = ('days'),  
Prescription_provider = (Select UserFirstName + ' '+ UserLastName from mst_User where UserID = OPPO.UserID),
Dispensing_provider = (Select UserFirstName + ' '+ UserLastName from mst_User where UserID = DPPO.UserID),
OPPO.DispensedByDate
from ord_PatientPharmacyOrder OPPO
LEFT JOIN dtl_RegimenMap RM ON RM.OrderID = OPPO.ptn_pharmacy_pk
LEFT JOIN dtl_PatientPharmacyOrder DPPO ON OPPO.ptn_pharmacy_pk = DPPO.ptn_pharmacy_pk
LEFT JOIN Patient P ON P.ptn_pk = OPPO.Ptn_pk
)ctx where ctx.OnCtx='Yes')cotph on cotph.Ptn_pk=OV.Ptn_Pk
 and DATEDIFF(day,cotph.DispensedByDate,OV.VisitDate)=0
LEFT JOIN (
		SELECT a.appdate,
		b.Name,
		a.Ptn_pk,
		a.Visit_pk
		FROM dtl_patientappointment a
		INNER JOIN mst_decode b ON a.appstatus = b.id
		WHERE a.deleteflag = 0 AND format(cast(a.AppDate AS DATE), 'yyyy-MM-dd') <> '1900-01-01' AND a.ModuleId IN(SELECT m.ModuleID FROM mst_module m WHERE m.ModuleName='CCC Patient Card MoH 257')) bapp ON bapp.Visit_pk = OV.Visit_Id
WHERE OV.VisitType=17 and MP.DeleteFlag = 0

UNION
--BLUECARD PHARMACY
select 

P.PersonId Person_Id,
P.Ptn_Pk,
format(cast(coalesce(t.DispensedByDate,t.OrderedByDate,t.VisitDate) AS DATE), 'yyyy-MM-dd') AS Encounter_Date,
NULL AS Encounter_ID,
'P' as Encounter_Type,
NULL AS Visit_scheduled,
NULL AS Visit_by,
NULL Visit_by_other,
NULL AS Nutritional_status,
NULL AS Who_stage,
NULL Presenting_complaints,
NULL Has_Known_allergies,
NULL Has_adverse_drug_reaction,
NULL Has_Chronic_illnesses_cormobidities,
NULL AS Clinical_notes,
NULL as Last_menstrual_period,
NULL as Pregnancy_status,
NULL as Wants_pregnancy,
NULL as Pregnancy_outcome,
NULL as Anc_number,
NULL AS Anc_profile,
NULL  as Expected_delivery_date,
NULL as Gravida,
NULL as Parity_term,
NULL as Parity_abortion,
NULL as Family_planning_status,
NULL Reason_not_using_family_planning,
NULL as General_examinations_findings,
NULL as System_review_finding,
NULL as Skin,
NULL as Skin_finding_notes,
NULL as Eyes,
NULL as Eyes_Finding_notes,
NULL as ENT,
NULL as ENT_finding_notes,
NULL as Chest,
NULL as Chest_finding_notes,
NULL as CVS,
NULL as CVS_finding_notes,
NULL as Abdomen,
NULL as Abdomen_finding_notes,
NULL as CNS,
NULL as CNS_finding_notes,
NULL as Genitourinary,
NULL as Genitourinary_finding_notes,
NULL as Treatment_plan,
NULL as Ctx_adherence,
cotph.OnCtx as Ctx_dispensed,
NULL as Dapsone_adherence,
NULL as Dapsone_dispensed,
NULL Morisky_forget_taking_drugs,
NULL Morisky_careless_taking_drugs,
NULL Morisky_stop_taking_drugs_feeling_worse,
NULL Morisky_stop_taking_drugs_feeling_better,
NULL Morisky_took_drugs_yesterday,
NULL Morisky_stop_taking_drugs_symptoms_under_control,
NULL Morisky_feel_under_pressure_on_treatment_plan,
NULL Morisky_how_often_difficulty_remembering,
NULL as Arv_adherence,
NULL Condom_Provided,
NULL Screened_for_substance_abuse,
NULL Pwp_Disclosure,
NULL Pwp_partner_tested,
NULL as Cacx_Screening,
NULL Screened_for_sti,
NULL as Sti_partner_notification,
NULL as Stability,
format(cast(t.ExpectedReturn AS DATE), 'yyyy-MM-dd') AS Next_appointment_date,
NULL Next_appointment_reason,
NULL Appointment_type,
NULL as Differentiated_care,
NULL as Voided
,t.UserID as Created_by
,t.CreateDate as Create_date
from(SELECT dateadd(day, d.Duration, CASE WHEN o.OrderedByDate > o.DispensedByDate THEN o.OrderedByDate ELSE o.DispensedByDate END) AS ExpectedReturn, 
o.DispensedByDate, o.OrderedByDate,
o.Ptn_pk, ov.VisitDate, ov.VisitType, ov.Visit_Id,
o.CreateDate,o.UserID,d.ptn_pharmacy_pk
FROM ord_PatientPharmacyOrder o 
INNER JOIN ord_Visit ov ON ov.Visit_Id = o.VisitID
INNER JOIN dtl_PatientPharmacyOrder d ON d.ptn_pharmacy_pk = o.ptn_pharmacy_pk
WHERE ov.VisitType = 4 AND d.Prophylaxis = 0  AND o.ProgID IN (SELECT ID FROM mst_Decode WHERE Name IN ('ART', 'PMTCT')) AND o.DispensedByDate IS NOT NULL and o.PatientMasterVisitId is null) t
INNER JOIN Patient P ON P.ptn_pk = t.Ptn_Pk
left join(select ctx.PersonId,ctx.OnCtx,ctx.DispensedByDate,ctx.Drug_name,ctx.Ptn_pk,ctx.ptn_pharmacy_pk from(select 
P.PersonId,
OPPO.Ptn_pk,
OPPO.ptn_pharmacy_pk,
OPPO.OrderedByDate,
NULL Encounter_ID,
RM.RegimenType,
OPPO.PatientMasterVisitId,

CASE WHEN (select top 1 DrugName from VW_Drug where DrugName like '%Sulfa/TMX-Cotrimoxazole%' AND Drug_pk = DPPO.Drug_Pk) IS NOT NULL THEN 'Yes'
 WHEN (select top 1 DrugName from VW_Drug where DrugName like '%Sulfa%tmx%' AND Drug_pk = DPPO.Drug_Pk) IS NOT NULL THEN 'Yes'
 WHEN (select top 1  DrugName from VW_Drug where DrugName like '%co%tri%' AND Drug_pk = DPPO.Drug_Pk) IS NOT NULL THEN 'Yes'
 WHEN (select top 1  DrugName from VW_Drug where DrugName like '%dapson%' AND Drug_pk = DPPO.Drug_Pk) IS NOT NULL THEN 'Yes'
 else NULL end as OnCtx,
(select top 1 DrugName from VW_Drug where Drug_pk = DPPO.Drug_Pk) Drug_name,
Dose = (1),
Unit = (select StrengthName from mst_Strength where StrengthId = (SELECT top 1 StrengthId FROM Lnk_DrugStrength where DrugId=DPPO.Drug_Pk)),
Frequency = (select top 1 Name from mst_Frequency where FrequencyID = DPPO.FrequencyID),
Duration = (DPPO.Duration),
Duration_units  = ('days'),  
Prescription_provider = (Select UserFirstName + ' '+ UserLastName from mst_User where UserID = OPPO.UserID),
Dispensing_provider = (Select UserFirstName + ' '+ UserLastName from mst_User where UserID = DPPO.UserID),
OPPO.DispensedByDate
from ord_PatientPharmacyOrder OPPO
LEFT JOIN dtl_RegimenMap RM ON RM.OrderID = OPPO.ptn_pharmacy_pk
LEFT JOIN dtl_PatientPharmacyOrder DPPO ON OPPO.ptn_pharmacy_pk = DPPO.ptn_pharmacy_pk
LEFT JOIN Patient P ON P.ptn_pk = OPPO.Ptn_pk
)ctx where ctx.OnCtx='Yes')cotph on cotph.Ptn_pk=t.Ptn_pk
 and cotph.ptn_pharmacy_pk=t.ptn_pharmacy_pk

left join( select 
vo.Ptn_Pk,
vo.VisitDate
FROM ord_Visit vo
WHERE vo.VisitType = 17) d on d.Ptn_Pk = t.Ptn_pk AND t.VisitDate = d.VisitDate
WHERE d.VisitDate is null
