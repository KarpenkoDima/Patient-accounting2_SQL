SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

/* [DispensaryMainTest].[dbo].[uspGetInvalidByAddress] */

CREATE PROCEDURE [dbo].[uspGetInvalidBenefitsByBirthOfDay]
	-- Add the parameters for the stored procedure here
	@BirthOfDay DATETIME NULL,
	@BirthOfDayEnd DATETIME NULL,
	@predicate NVARCHAR(10)
	
AS
BEGIN
    	SET NOCOUNT ON;
       -- Insert statements for procedure here
	SET @predicate = RTRIM(LTRIM(@predicate));

IF @predicate = '>' 
BEGIN
	WITH CTE_( CustomerID)
	AS (SELECT [CustomerID]
      FROM dbo.vGetCustomers AS vgc
	WHERE vgc.Birthday > @BirthOfDay	
	)
    	SELECT
    		ibc.invID,
    		ibc.BenefitsID
    	FROM
    		 vGetInvalid_BenefitsCategory AS ibc
    		INNER JOIN vGetInvalid AS vgi
    		ON ibc.invID = vgi.InvalidID
    		INNER	JOIN CTE_ AS cte_
				  ON  cte_.CustomerID = vgi.CustomerID    	
	END 
	
	ELSE IF @predicate = '='
     BEGIN
     WITH CTE_( CustomerID)
	AS (SELECT [CustomerID]
      FROM dbo.vGetCustomers AS vgc
	WHERE vgc.Birthday = @BirthOfDay
	)

	SELECT
    		ibc.invID,
    		ibc.BenefitsID
    	FROM
    		 vGetInvalid_BenefitsCategory AS ibc
    		INNER JOIN vGetInvalid AS vgi
    		ON ibc.invID = vgi.InvalidID
    		INNER	JOIN CTE_ AS cte_
				  ON  cte_.CustomerID = vgi.CustomerID;    	
     END
     
 ELSE IF @predicate = '>='
     BEGIN
     WITH CTE_( CustomerID)
	AS (SELECT [CustomerID]
      FROM dbo.vGetCustomers AS vgc
	WHERE vgc.Birthday >= @BirthOfDay
	)

SELECT
    		ibc.invID,
    		ibc.BenefitsID
    	FROM
    		 vGetInvalid_BenefitsCategory AS ibc
    		INNER JOIN vGetInvalid AS vgi
    		ON ibc.invID = vgi.InvalidID
    		INNER	JOIN CTE_ AS cte_
				  ON  cte_.CustomerID = vgi.CustomerID;
     END
     
 ELSE IF @predicate = '<='
     BEGIN
     	WITH CTE_( CustomerID)
	AS (SELECT [CustomerID]
      FROM dbo.vGetCustomers AS vgc
	WHERE vgc.Birthday <= @BirthOfDay
	)
SELECT
    		ibc.invID,
    		ibc.BenefitsID
    	FROM
    		 dbo.vGetInvalid_BenefitsCategory AS ibc
    		INNER JOIN vGetInvalid AS vgi
    		ON ibc.invID = vgi.InvalidID
    		INNER	JOIN CTE_ AS cte_
				  ON  cte_.CustomerID = vgi.CustomerID;
     END
     
  ELSE IF @predicate = '<'
     BEGIN
     WITH CTE_( CustomerID)
	AS (SELECT [CustomerID]
      FROM dbo.vGetCustomers AS vgc	 
	WHERE vgc.Birthday < @BirthOfDay
)

SELECT
    		ibc.invID,
    		ibc.BenefitsID
    	FROM
    		 vGetInvalid_BenefitsCategory AS ibc
    		INNER JOIN vGetInvalid AS vgi
    		ON ibc.invID = vgi.InvalidID
    		INNER	JOIN CTE_ AS cte_
				  ON  cte_.CustomerID = vgi.CustomerID;
     END
   
   ELSE IF @predicate = '<>'
     BEGIN
WITH CTE_( CustomerID)
	AS (SELECT [CustomerID]
      FROM dbo.vGetCustomers AS vgc
	WHERE vgc.Birthday <> @BirthOfDay
	)

SELECT
    		ibc.invID,
    		ibc.BenefitsID
    	FROM
    		 vGetInvalid_BenefitsCategory AS ibc
    		INNER JOIN vGetInvalid AS vgi
    		ON ibc.invID = vgi.InvalidID
    		INNER	JOIN CTE_ AS cte_
				  ON  cte_.CustomerID = vgi.CustomerID;
     END
     
   ELSE IF @predicate = 'ÌÅÆÄÓ'
     BEGIN
     WITH CTE_( CustomerID)
	AS (SELECT [CustomerID]
      FROM dbo.vGetCustomers AS vgc
	 WHERE vgc.Birthday BETWEEN @BirthOfDay AND @BirthOfDayEnd
	 )

SELECT
    		ibc.invID,
    		ibc.BenefitsID
    	FROM
    		 vGetInvalid_BenefitsCategory AS ibc
    		INNER JOIN vGetInvalid AS vgi
    		ON ibc.invID = vgi.InvalidID
    		INNER	JOIN CTE_ AS cte_
				  ON  cte_.CustomerID = vgi.CustomerID;
     END
END

GO

GRANT EXECUTE ON [dbo].[uspGetInvalidBenefitsByBirthOfDay] TO [Sensitive_low] AS [dbo]
GO
