SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


/* [DispensaryMainTest].[dbo].[uspDeleteInvalidBenefitsCategory] */

/* DispensaryMain.[dbo].[uspDeleteInvalidBenefitsCategory] */

-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [uspDeleteInvalidBenefitsCategory]
	-- Add the parameters for the stored procedure here
	@InvalidID INT, 
	@BenefitsCategory INT
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	DELETE FROM Invalid_BenefitsCategory
	WHERE invID = @InvalidID AND BenefitsID=@BenefitsCategory
END

GO
