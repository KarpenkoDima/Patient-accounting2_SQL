SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

/************************************************************
 * Generated by SoftTree SQL Assistant � 7.5.502
 * Time:   04.03.2018 21:10:06
 * Source: uspGetBenefitsCategoryForInvalidID, uspGetInvalidByAddress, uspGetInvalidByApppTpr, 
 *         uspGetInvalidByBenefitsCategory, uspGetInvalidByBirthOfDay, uspGetInvalidByCustomerID, 
 *         uspGetInvalidByGender, uspGetInvalidByLand, uspGetInvalidByLastName
 ************************************************************/

/* [DispensaryMainTest].[dbo].[uspGetBenefitsCategoryForInvalidID] */

/* DispensaryMain.[dbo].[uspGetBenefitsCategoryForInvalidID] */

CREATE PROCEDURE uspGetBenefitsCategoryForInvalidID
	@invalidID INT = NULL
	--@BenefitsCayegory VARCHAR(50) =NULL OUT
AS 
	DECLARE @BenefitsCayegory VARCHAR(50);
	--IF @BenefitsCayegory IS NULL
    SET @BenefitsCayegory = ''
	SELECT @BenefitsCayegory = @BenefitsCayegory + bc.Name+', '
	FROM Invalid_BenefitsCategory AS ibc
	INNER JOIN BenefitsCategory AS bc
			  ON bc.BenefitsCategoryID = ibc.BenefitsID
	WHERE ibc.invID = @invalidID
	SELECT @BenefitsCayegory;

GO

GRANT EXECUTE ON [dbo].[uspGetBenefitsCategoryForInvalidID] TO [Sensitive_low] AS [dbo]
GO
