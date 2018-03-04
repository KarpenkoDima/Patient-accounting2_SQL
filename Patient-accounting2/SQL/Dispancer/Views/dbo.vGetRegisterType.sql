SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


/* [DispensaryMainTest].[dbo].[vGetRegisterType] */

/* DispensaryMain.[dbo].[vGetRegisterType] */

CREATE VIEW [dbo].[vGetRegisterType]
AS
SELECT RegisterTypeID, [Name], NotaBene
FROM            dbo.RegisterType

GO

GRANT SELECT ON [dbo].[vGetRegisterType] TO [Sensitive_low] AS [dbo]
GO
