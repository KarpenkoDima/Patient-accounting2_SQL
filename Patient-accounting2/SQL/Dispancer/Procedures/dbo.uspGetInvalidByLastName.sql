SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


/* [DispensaryMainTest].[dbo].[uspGetInvalidByLastName] */

-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[uspGetInvalidByLastName]
	-- Add the parameters for the stored procedure here
	@LastName NVARCHAR(100)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	SELECT vgi.ChiperReceptID,
           vgi.CustomerID,
           vgi.DataInvalidity,
           vgi.DateIncapable,
           vgi.DisabilityGroupID,
           vgi.Incapable,
           vgi.InvalidID,
           vgi.ModifiedDate,
           vgi.PeriodInvalidity FROM dbo.vGetInvalid AS vgi
	WHERE EXISTS (SELECT vgc.CustomerID FROM dbo.vGetCustomers AS vgc WHERE vgi.CustomerID = vgc.CustomerID 
			AND 
				  lastname LIKE @LastName + '%')
	
END

GO

GRANT EXECUTE ON [dbo].[uspGetInvalidByLastName] TO [Sensitive_low] AS [dbo]
GO
