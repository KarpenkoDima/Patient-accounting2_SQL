SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


/* [DispensaryMainTest].[dbo].[vGetRegister] */

/* DispensaryMain.[dbo].[vGetRegister] */

CREATE VIEW [dbo].[vGetRegister]
AS
	SELECT r.[RegisterID]
      ,[FirstRegister]
      ,[FirstDeregister]
      ,[SecondRegister]
      ,[Diagnosis]
      ,[RegisterTypeID]
      ,[CustomerID]
      ,[WhyDeRegisterID]
      ,[SecondDeRegister]
      ,[SecondRegisterTypeID]
      ,[WhySecondDeRegisterID]
      ,[LandID]
      ,rnb.[NotaBene]
      ,[ModifiedDate]
  FROM [dbo].[Register] AS r
  LEFT JOIN RegisterNotaBene AS rnb
  ON r.RegisterID = rnb.RegisterID

GO

GRANT SELECT ON [dbo].[vGetRegister] TO [Sensitive_low] AS [dbo]
GO
