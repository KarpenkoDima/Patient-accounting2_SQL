SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


/* DispensaryMain.[dbo].[uspDeleteApppTpr] */

CREATE PROCEDURE [dbo].[uspDeleteApppTpr]
/***********************************************************
* Procedure description: This procedure is used for 
*                        deleting records from table 
*                        Land
* Date:   13.12.2015 
* Author:  Author: DIMA KARPENKO
*
* Changes
* Date        Modified By            Comments
************************************************************
* 13.12.2015  DIMA     Initial version
************************************************************/
(
    @ApppTprID int
)
AS
BEGIN
    SET NOCOUNT ON
    DECLARE @rowcount INT, @error INT

	SET XACT_ABORT ON
    -- start transaction
	BEGIN TRANSACTION

    -- delete record using the specified criteria, 1 record deletion is expected
    DELETE FROM [dbo].APPPTPR
    WHERE  appptpr = @ApppTprID

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

GRANT EXECUTE ON [dbo].[uspDeleteApppTpr] TO [Sensitive_medium] AS [dbo]
GO
