SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


/* DispensaryMain.[dbo].[uspDeleteCustomer] */

CREATE PROCEDURE [dbo].[uspDeleteCustomer]
/***********************************************************
* Procedure description: This procedure is used for 
*                        deleting records from table 
*                        Customer
* Date:   13.12.2015 
* Author: DIMA KARPENKO
*
* Changes
* Date        Modified By            Comments
************************************************************
* 13.12.2015  DIMA     Initial version
************************************************************/
(
    @CustomerID INT
)
AS
BEGIN
    SET NOCOUNT ON
    DECLARE @rowcount INT, @error INT

    -- start transaction
    SET XACT_ABORT ON
	BEGIN TRANSACTION
	SELECT * FROM dbo.Customer WITH(HOLDLOCK) 
	INNER JOIN dbo.Address AS adr ON adr.CustomerID = Customer.CustomerID
	INNER JOIN dbo.Register ON Register.CustomerID = Customer.CustomerID
	INNER JOIN dbo.Invalid ON Invalid.CustomerID = Customer.CustomerID
	WHERE Customer.CustomerID = @CustomerID
	
    -- delete record using the specified criteria, 1 record deletion is expected
    DELETE FROM [dbo].[Customer]
    WHERE  CustomerID = @CustomerID

    -- capture operation completion code and number of records affected
	SELECT @rowcount = @@ROWCOUNT, 
           @error = @@ERROR

    -- check for errors
	IF @error != 0
    BEGIN
        -- cancel transaction, undo changes
        ROLLBACK TRANSACTION

		-- report error and exit with non-zero exit code
        RAISERROR('Unable to delete record. See previous message for details.', 16, 1) 
		RETURN @error
    END
    -- check for rows updated
    IF @rowcount != 1 
    BEGIN
        -- cancel transaction, undo changes
        ROLLBACK TRANSACTION

		-- report error and exit with non-zero exit code
		IF @rowcount = 0
            RAISERROR('Warning. No records found for the specified criteria, while just 1 was expected.', 10, 1) 
		ELSE
            RAISERROR('Critical error. More than 1 record found for the specified criteria, while just 1 was expected.', 16, 1) 
		RETURN 1
    END 

    -- commit changes and return 0 code indicating successful completion
    COMMIT TRANSACTION
    RETURN 0
END


GO

GRANT EXECUTE ON [dbo].[uspDeleteCustomer] TO [Sensitive_high] AS [dbo]
GO
