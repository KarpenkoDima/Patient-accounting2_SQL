SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


/* [DispensaryMainTest].[dbo].[vGetBenefitsCategory] */

/* DispensaryMain.[dbo].[vGetBenefitsCategory] */

CREATE VIEW [dbo].[vGetBenefitsCategory]
AS
SELECT [BenefitsCategoryID]
      ,[Name]
      ,[NotaBene]
  FROM [dbo].[BenefitsCategory]

GO

GRANT SELECT ON [dbo].[vGetBenefitsCategory] TO [Sensitive_low] AS [dbo]
GO
