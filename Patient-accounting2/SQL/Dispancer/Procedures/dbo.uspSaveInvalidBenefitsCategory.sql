SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO



/* [DispensaryMainTest].[dbo].[uspSaveInvalidBenefitsCategory] */

/* DispensaryMain.[dbo].[uspSaveInvalidBenefitsCategory] */

-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[uspSaveInvalidBenefitsCategory]
	-- Add the parameters for the stored procedure here
	@InvalidID INT, 
	@BenefitsCategoryID INT
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
    IF NOT EXISTS(
    	SELECT * FROM BenefitsCategory AS bc
    	WHERE bc.BenefitsCategoryID = @BenefitsCategoryID
    )
    BEGIN
    	ROLLBACK TRANSACTION
    		RAISERROR ('Кретическая ошибка - нет такой категории льгот.', 16, 1)
    		RETURN 1
    END
    IF NOT EXISTS 
    (
    	SELECT * FROM Invalid AS i
    	WHERE i.InvalidID = @InvalidID
    )
    BEGIN
    	ROLLBACK TRANSACTION
    		RAISERROR ('Кретическая ошибка - нет такой записи об инванлидности.', 16, 1)
    		RETURN 1
    END
    IF NOT EXISTS(
    	SELECT *
    	FROM Invalid_BenefitsCategory AS ibc
    	WHERE ibc.invID = @InvalidID AND ibc.BenefitsID=@BenefitsCategoryID
    )
    INSERT INTO dbo.Invalid_BenefitsCategory
    (
    	invID,
    	BenefitsID
    )
    VALUES
    (
    	@InvalidID,
    	@BenefitsCategoryID
    )
END


GO
