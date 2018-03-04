SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


/* [DispensaryMainTest].[dbo].[vGetDisabilityGroup] */

/* DispensaryMain.[dbo].[vGetDisabilityGroup] */

/****** Script for SelectTopNRows command from SSMS  ******/
CREATE VIEW [dbo].[vGetDisabilityGroup]
AS
SELECT [DisabilityGroupID]
      ,[Name]
      ,[NotaBene]
  FROM [dbo].[DisabilityGroup]

GO

GRANT SELECT ON [dbo].[vGetDisabilityGroup] TO [Sensitive_low] AS [dbo]
GO
