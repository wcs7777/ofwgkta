DELIMITER //

DROP PROCEDURE IF EXISTS crieUsuarioBancoOfwgkta //
CREATE PROCEDURE crieUsuarioBancoOfwgkta()
BEGIN
	SELECT
		count(*)
	INTO
		@existe
	FROM
		mysql.user
	WHERE
		mysql.user.host = 'localhost' AND
		mysql.user.user = 'usuario_ofwgkta'
	LIMIT 1;

	IF @existe THEN
		DROP USER 'usuario_ofwgkta'@'localhost';
	END IF;

	CREATE USER
		'usuario_ofwgkta'@'localhost'
	IDENTIFIED BY
		'oddfuture';

	GRANT
		EXECUTE
	ON
		`ofwgkta`.*
	TO
		'usuario_ofwgkta'@'localhost';

	FLUSH PRIVILEGES;
END //

CALL crieUsuarioBancoOfwgkta() //
DROP PROCEDURE IF EXISTS crieUsuarioBancoOfwgkta //

DELIMITER ;
