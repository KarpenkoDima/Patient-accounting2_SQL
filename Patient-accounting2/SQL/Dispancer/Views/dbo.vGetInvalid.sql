SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


/* [DispensaryMainTest].[dbo].[vGetInvalid] */

/* DispensaryMain.[dbo].[vGetInvalid] */

CREATE VIEW [dbo].[vGetInvalid]
AS
SELECT [InvalidID]
      ,[DisabilityGroupID]
      ,[DataInvalidity]
      ,[PeriodInvalidity]
      ,[ChiperReceptID]
      ,[Incapable]
      ,[DateIncapable]
      ,[CustomerID]
      ,[ModifiedDate]
  FROM [dbo].[Invalid]

GO

GRANT SELECT ON [dbo].[vGetInvalid] TO [Sensitive_low] AS [dbo]
GO
