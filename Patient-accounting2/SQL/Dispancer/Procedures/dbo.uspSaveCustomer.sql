SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

/* DispensaryMain.[dbo].[uspSaveCustomer] */

CREATE PROCEDURE [dbo].[uspSaveCustomer]
/***********************************************************
* Code generated by SoftTree SQL Assistant � v7.4.435
*
* Procedure description: This procedure is used for adding 
*                        and updating records in table 
*                        Customer
* Date:   13.12.2015 
* Author: DIMA
*
* Changes
* Date        Modified By            Comments
************************************************************
* 13.12.2015  DIMA     Initial version
************************************************************/
(
	--@id INT OUT,
    @CustomerID int = NULL OUT,
    @MedCard int = NULL,
    @CodeCustomer int = NULL,
    @LastName nvarchar(100) = NULL,
    @FirstName nvarchar(100) = NULL,
    @MiddleName nvarchar(100) = NULL,
    --@Gender nchar(1) = '-',
    @Birthday datetime = NULL,
    @APPPTPRID INT = NULL,
    @GenderID INT = NULL,
    --@ModifyDate datetime = NULL,
    @Arch BIT = NULL,
    @NotaBene NTEXT = NULL
)
AS
BEGIN
    SET NOCOUNT ON
    DECLARE @rowcount INT, @error INT, @custID INT--, @id INT

    -- start transaction
	BEGIN TRANSACTION

    -- check if the specified record already exists, if yes, update it, if no, create it
    IF NOT EXISTS 
    (    
         SELECT * 
         FROM [dbo].[Customer]
         WHERE  CustomerID = @CustomerID
    )
    BEGIN 
         -- insert new record
         INSERT INTO [dbo].[Customer]
         (
             MedCard,
             CodeCustomer,
             LastName,
             FirstName,
             MiddleName,
             --Gender,
             Birthday,
		     APPPTPRID,
		     GenderID,
             ModifyDate,
             Arch
         )
         VALUES 
         (
             @MedCard,
             @CodeCustomer,
             @LastName,
             @FirstName,
             @MiddleName,
             --@Gender,
             @Birthday,
             @APPPTPRID,
             @GenderID,
             GETDATE(),
             @Arch
         )
         
    END 
    ELSE
    BEGIN
         -- update existing record
         UPDATE [dbo].[Customer]
         SET MedCard = @MedCard,
             CodeCustomer = @CodeCustomer,
             LastName = @LastName,
             FirstName = @FirstName,
             MiddleName = @MiddleName,
             --Gender = @Gender,
             Birthday = @Birthday,
             APPPTPRID = @APPPTPRID,
             GenderID = @GenderID,
             ModifyDate = GETDATE(),
             Arch = @Arch
         WHERE  CustomerID = @CustomerID
    END

    -- capture operation completion code and number of records affected
	SELECT @rowcount = @@ROWCOUNT, 
           @error = @@ERROR,
           @custID = SCOPE_IDENTITY()

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
    IF @custID IS NOT NULL
        SELECT @CustomerID=@custID;-- AS NewRecordID
    ELSE SELECT @CustomerID
    EXEC uspSaveCustomerNotaBene @CustomerID, @NotaBene
    RETURN 0
END

GO

GRANT EXECUTE ON [dbo].[uspSaveCustomer] TO [Sensitive_medium] AS [dbo]
GO