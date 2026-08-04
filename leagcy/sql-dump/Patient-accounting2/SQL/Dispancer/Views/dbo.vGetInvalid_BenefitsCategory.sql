SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


/* [DispensaryMainTest].[dbo].[vGetInvalid_BenefitsCategory] */

/* DispensaryMain.[dbo].[vGetInvalid_BenefitsCategory] */

/****** Script for SelectTopNRows command from SSMS  ******/
CREATE VIEW [dbo].[vGetInvalid_BenefitsCategory]
AS
SELECT [invID]
      ,[BenefitsID]
  FROM [dbo].[Invalid_BenefitsCategory]

GO

GRANT SELECT ON [dbo].[vGetInvalid_BenefitsCategory] TO [Sensitive_low] AS [dbo]
GO
