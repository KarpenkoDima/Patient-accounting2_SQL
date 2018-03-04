SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

/************************************************************
 * Generated by SoftTree SQL Assistant � 7.5.502
 * Time:   04.03.2018 21:12:11
 * Source: uspSaveApppTPR, uspSaveBenefitsCategory, uspSaveChiperRecept, uspSaveDisabilityGroup, 
 *         uspSaveInvalid, uspSaveInvalidBenefitsCategory, uspSaveLand, uspSaveRegister, 
 *         uspSaveRegisterType
 ************************************************************/

/* [DispensaryMainTest].[dbo].[uspSaveApppTPR] */

/* DispensaryMain.[dbo].[uspSaveApppTPR] */


/* [DispensaryMainTest].[dbo].[uspSaveBenefitsCategory] */

/* DispensaryMain.[dbo].[uspSaveBenefitsCategory] */

CREATE PROCEDURE [dbo].[uspSaveBenefitsCategory]
/***********************************************************
* Code generated by SoftTree SQL Assistant � v7.4.435
*
* Procedure description: This procedure is used for adding 
*                        and updating records in table 
*                        Land
* Date:   13.12.2015 
* Author: DIMA
*
* Changes
* Date        Modified By            Comments
************************************************************
* 13.12.2015  DIMA     Initial version
************************************************************/
(
    @BenefitsCategoryID int = NULL OUT,
    @Name NVARCHAR(100) = NULL,
    @NotaBene NVARCHAR(100) = NULL
)
AS
BEGIN
    SET NOCOUNT ON
    DECLARE @rowcount INT, @error INT, @id INT

    -- start transaction
	BEGIN TRANSACTION

    -- check if the specified record already exists, if yes, update it, if no, create it
    IF NOT EXISTS 
    (    
         SELECT * 
         FROM [dbo].[BenefitsCategory]
         WHERE BenefitsCategoryID = @BenefitsCategoryID
    )
    BEGIN 
         -- insert new record
         INSERT INTO [dbo].[BenefitsCategory]         
         (
             Name,
             NotaBene
         )
         VALUES 
         (
             @Name,
             @NotaBene
         )
    END 
    ELSE
    BEGIN
         -- update existing record
         UPDATE [dbo].[BenefitsCategory]                  
         SET
         	-- RegisterTypeID -- this column value is auto-generated
         	Name = @Name,
         	NotaBene = @NotaBene
         WHERE BenefitsCategoryID = @BenefitsCategoryID
    END

    -- capture operation completion code and number of records affected
	SELECT @rowcount = @@ROWCOUNT, 
           @error = @@ERROR,
           @id = SCOPE_IDENTITY()

	IF @error != 0
    BEGIN
        -- cancel transaction, undo changes
        ROLLBACK TRANSACTION

		-- report error and exit with non-zero exit code
        RAISERROR('Unable to update or insert new record. See previous message for details.', 16, 1) 
		RETURN @error
    END
    IF @rowcount != 1 
    BEGIN
        -- cancel transaction, undo changes
        ROLLBACK TRANSACTION

		-- report error and exit with non-zero exit code
        RAISERROR('Critical error. More than 1 record found for the specified criteria, just 1 is expected.', 16, 1) 
		RETURN 1
    END 

    -- commit changes and return 0 code indicating successful completion
    COMMIT TRANSACTION

	-- if operation type 'Add record', return result set with the last inserted column value 
    IF @id IS NOT NULL
        SELECT @BenefitsCategoryID = @id
    ELSE SELECT @BenefitsCategoryID
    RETURN 0
END

GO
