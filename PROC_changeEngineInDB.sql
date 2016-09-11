SET @db_name := 'xxx';
SET @engine_from := 'MyISAM';
SET @engine_to := 'InnoDB';

CALL changeEngineInDB(@db_name, @engine_from, @engine_to);

DROP PROCEDURE IF EXISTS `changeEngineInDB`;
#PROCEDURE
DELIMITER $$
CREATE DEFINER=`root`@`localhost` PROCEDURE `changeEngineInDB`(IN $db_name VARCHAR(45),

	IN $engine_from VARCHAR(35), IN $engine_to VARCHAR(35))
BEGIN
	DECLARE $done TINYINT(1) DEFAULT 0;
	DECLARE $table_name VARCHAR(300);
	DECLARE $alter_loop_cycles INT(11) DEFAULT 0;

	DECLARE EXIT HANDLER FOR SQLEXCEPTION, SQLWARNING, NOT FOUND
	BEGIN
		GET DIAGNOSTICS CONDITION 1 @p1 = RETURNED_SQLSTATE, @p2 = MESSAGE_TEXT;
		SELECT 'Error' AS `status`, @p1 AS `sql_state`, @p2 AS `message`;
	END;

	BEGIN
		DECLARE $tableNameCursor CURSOR FOR SELECT
			t.TABLE_NAME
			FROM information_schema.TABLES AS t
			WHERE t.TABLE_SCHEMA = $db_name AND t.ENGINE = $engine_from;

		DECLARE CONTINUE HANDLER FOR NOT FOUND SET $done = 1;

		SET $done = 0;
		SET $alter_loop_cycles = 0;

		OPEN $tableNameCursor;
		alter_loop: LOOP
			FETCH $tableNameCursor INTO $table_name;

			IF $done THEN
				LEAVE alter_loop;
			END IF;
			BEGIN
				SET @alter_sql = CONCAT('ALTER TABLE ',$db_name,'.',$table_name,' ENGINE=InnoDB;');
				PREPARE $query FROM	@alter_sql;
				EXECUTE $query;
				DEALLOCATE PREPARE $query;
			END;
			SET $alter_loop_cycles = $alter_loop_cycles + 1;
		END LOOP;
	END;
	SELECT CONCAT('Система хранения ',
								$engine_from,' изменена на ',$engine_to,' для ',
								$alter_loop_cycles,' таблиц.') AS `message`;
END$$