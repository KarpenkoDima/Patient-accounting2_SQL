SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


/* [DispensaryMainTest].[dbo].[uspSaveRegister] */

/* DispensaryMain.[dbo].[uspSaveRegister] */

CREATE PROCEDURE [dbo].[uspSaveRegister]
/***********************************************************
* Code generated by SoftTree SQL Assistant � v7.4.435
*
* Procedure description: This procedure is used for adding 
*                        and updating records in table 
*                        Register
* Date:   13.12.2015 
* Author: DIMA
*
* Changes
* Date        Modified By            Comments
************************************************************
* 13.12.2015  DIMA     Initial version
************************************************************/
(
    @RegisterID int = NULL OUT,
    @FirstRegister datetime = NULL,
    @FirstDeregister datetime = NULL,
    @SecondRegister datetime = NULL,
    @SecondDeRegister datetime = NULL,
    @Diagnosis nvarchar(10) = NULL,
    --@DataDiagnosis datetime = NULL,
    --@DiagnosisDZ nvarchar(20) = NULL,
    @RegisterTypeID int = NULL,
    @CustomerID INT,
    @WhyDeRegister INT = NULL,
    @WhySecondDeRegister INT = NULL,
    @SecondRegisterTypeID INT = NULL,
    @LandID int = NULL,
    @NotaBene NTEXT,
    @ModifiedDate datetime = NULL
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
         FROM [dbo].[Register]
         WHERE  RegisterID = @RegisterID
    )    
    BEGIN 
         -- insert new record
         IF	NOT EXISTS (
         	SELECT *
         	FROM Customer AS c
         	WHERE c.CustomerID = @CustomerID
         )
        BEGIN
			-- cancel transaction, undo changes
			ROLLBACK TRANSACTION

			-- report error and exit with non-zero exit code
			RAISERROR('����������� ������ - ��� �������� � ����� ID.', 16, 1) 
			RETURN 1
		END             	
    SET @ModifiedDate = GETDATE();
         INSERT INTO [dbo].[Register]
         (
             FirstRegister,
             FirstDeregister,
             SecondRegister,
             SecondDeRegister,
             Diagnosis,
             DataDiagnosis,
             --DiagnosisDZ,
             RegisterTypeID,
             CustomerID,
             WhyDeRegisterID,
             WhySecondDeRegisterID,
             SecondRegisterTypeID,
             LandID,
             NotaBene,
             ModifiedDate
         )
         VALUES 
         (
             @FirstRegister,
             @FirstDeregister,
             @SecondRegister,
             @SecondDeRegister,
             @Diagnosis,
             @FirstRegister,
             --@DiagnosisDZ,
             @RegisterTypeID,
             @CustomerID,
             @WhyDeRegister,
             @WhySecondDeRegister,
             @SecondRegisterTypeID,
             @LandID,
             @NotaBene,
             @ModifiedDate
         )
    END 
    ELSE
    BEGIN
         -- update existing record
         IF @ModifiedDate IS NULL
         BEGIN
         	SET @ModifiedDate = GETDATE();
         END         
         UPDATE [dbo].[Register]
         SET FirstRegister = @FirstRegister,
             FirstDeregister = @FirstDeregister,
             SecondRegister = @SecondRegister,
             SecondDeRegister = @SecondDeRegister,
             Diagnosis = @Diagnosis,
             DataDiagnosis = @FirstRegister,
             --DiagnosisDZ = @DiagnosisDZ,
             RegisterTypeID = @RegisterTypeID,
             SecondRegisterTypeID = @SecondRegisterTypeID,
             --CustomerID = @CustomerID,
             WhyDeRegisterID = @WhyDeRegister,
             WhySecondDeRegisterID = @WhySecondDeRegister,
             LandID = @LandID,
             NotaBene = @NotaBene,             
             ModifiedDate = @ModifiedDate
         WHERE  RegisterID = @RegisterID  AND CustomerID = @CustomerID
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
        SELECT @id AS NewRecordID
    RETURN 0
END

GO

GRANT EXECUTE ON [dbo].[uspSaveRegister] TO [Sensitive_medium] AS [dbo]
GO
