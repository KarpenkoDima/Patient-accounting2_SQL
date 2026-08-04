SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


/* [DispensaryMainTest].[dbo].[vGetApppTpr] */

/* DispensaryMain.[dbo].[vGetApppTpr] */

/****** Script for SelectTopNRows command from SSMS  ******/
CREATE VIEW [dbo].[vGetApppTpr]
AS
SELECT [APPPTPR] AS [APPPTPRID]
      ,[Name]
  FROM [dbo].[APPPTPR]

GO

GRANT SELECT ON [dbo].[vGetApppTpr] TO [Sensitive_low] AS [dbo]
GO
