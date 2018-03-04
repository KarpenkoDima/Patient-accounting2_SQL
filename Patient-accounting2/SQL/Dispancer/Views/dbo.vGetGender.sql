SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


/* [DispensaryMainTest].[dbo].[vGetGender] */

/* DispensaryMain.[dbo].[vGetGender] */

/****** Script for SelectTopNRows command from SSMS  ******/
CREATE VIEW [dbo].[vGetGender]
AS
SELECT [GenderID]
      ,[Name]
  FROM [dbo].[Gender]

GO

GRANT SELECT ON [dbo].[vGetGender] TO [Sensitive_low] AS [dbo]
GO
