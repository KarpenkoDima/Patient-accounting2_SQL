SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


/* [DispensaryMainTest].[dbo].[uspGetRegisterByLastName] */

-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[uspGetRegisterByLastName]
	-- Add the parameters for the stored procedure here
	@LastName NVARCHAR(100)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	SELECT vgr.CustomerID,
           vgr.Diagnosis,
           vgr.FirstDeregister,
           vgr.FirstRegister,
           vgr.LandID,
           vgr.ModifiedDate,
           vgr.NotaBene,
           vgr.RegisterID,
           vgr.RegisterTypeID,
           vgr.SecondDeRegister,
           vgr.SecondRegister,
           vgr.SecondRegisterTypeID,
           vgr.WhyDeRegisterID,
           vgr.WhySecondDeRegisterID 	FROM dbo.vGetRegister AS vgr
	WHERE EXISTS (SELECT vgc.CustomerID FROM dbo.vGetCustomers AS vgc WHERE vgr.CustomerID = vgc.CustomerID 
			AND 
				  lastname LIKE @LastName + '%')
	
END

GO
