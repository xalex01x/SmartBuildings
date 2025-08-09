-- MySQL Workbench Forward Engineering

SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0;
SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0;
SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION';

-- -----------------------------------------------------
-- Schema mydb
-- -----------------------------------------------------

-- -----------------------------------------------------
-- Table `AreaGeografica`
-- -----------------------------------------------------
DROP TABLE IF EXISTS `AreaGeografica` ;

CREATE TABLE IF NOT EXISTS `AreaGeografica` (
  `Area` VARCHAR(45) NOT NULL,
  PRIMARY KEY (`Area`))
ENGINE = InnoDB;


-- -----------------------------------------------------
-- Table `Rischio`
-- -----------------------------------------------------
DROP TABLE IF EXISTS `Rischio` ;

CREATE TABLE IF NOT EXISTS `Rischio` (
  `Nome` VARCHAR(45) NOT NULL,
  `Area` VARCHAR(45) NOT NULL,
  `Coefficiente` INT NULL, CHECK (`Coefficiente` >0 AND `Coefficiente` <=5),
  `UltimoUpdate` DATE NULL,
  PRIMARY KEY (`Nome`, `Area`),
  INDEX `fk_Rischio_AreaGeografica_idx` (`Area` ASC) VISIBLE,
  CONSTRAINT `fk_Rischio_AreaGeografica`
    FOREIGN KEY (`Area`)
    REFERENCES `AreaGeografica` (`Area`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION)
ENGINE = InnoDB;


-- -----------------------------------------------------
-- Table `Edificio`
-- -----------------------------------------------------
DROP TABLE IF EXISTS `Edificio` ;

CREATE TABLE IF NOT EXISTS `Edificio` (
  `Codice` VARCHAR(13) NOT NULL,
  `Tipologia` VARCHAR(45) NULL,
  `Latitudine` FLOAT(5) NULL,
  `Longitudine` FLOAT(5) NULL,
  `Area` VARCHAR(45) NOT NULL,
  PRIMARY KEY (`Codice`),
  INDEX `fk_Edificio_AreaGeografica1_idx` (`Area` ASC) VISIBLE,
  CONSTRAINT `fk_Edificio_AreaGeografica1`
    FOREIGN KEY (`Area`)
    REFERENCES `AreaGeografica` (`Area`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION)
ENGINE = InnoDB;


-- -----------------------------------------------------
-- Table `Calamita`
-- -----------------------------------------------------
DROP TABLE IF EXISTS `Calamita` ;

CREATE TABLE IF NOT EXISTS `Calamita` (
  `Latitudine` FLOAT(5) NOT NULL,
  `Longitudine` FLOAT(5) NOT NULL,
  `Timestamp` DATETIME NOT NULL,
  `Evento` VARCHAR(45) NULL,
  `Magnitudo` INT NULL,
  PRIMARY KEY (`Latitudine`, `Longitudine`, `Timestamp`))
ENGINE = InnoDB;


-- -----------------------------------------------------
-- Table `Percezione`
-- -----------------------------------------------------
DROP TABLE IF EXISTS `Percezione` ;

CREATE TABLE IF NOT EXISTS `Percezione` (
  `Latitudine` FLOAT(5) NOT NULL,
  `Longitudine` FLOAT(5) NOT NULL,
  `Timestamp` DATETIME NOT NULL,
  `CodEd` VARCHAR(13) NOT NULL,
  `Intensita` INT NOT NULL,
  PRIMARY KEY (`Latitudine`, `Longitudine`, `Timestamp`, `CodEd`),
  INDEX `fk_table2_Edificio1_idx` (`CodEd` ASC) VISIBLE,
  CONSTRAINT `fk_Percezione_Calamita1`
    FOREIGN KEY (`Latitudine` , `Longitudine` , `Timestamp`)
    REFERENCES `Calamita` (`Latitudine` , `Longitudine` , `Timestamp`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION,
  CONSTRAINT `fk_Percezione_Edificio1`
    FOREIGN KEY (`CodEd`)
    REFERENCES `Edificio` (`Codice`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION)
ENGINE = InnoDB;


-- -----------------------------------------------------
-- Table `Stato`
-- -----------------------------------------------------
DROP TABLE IF EXISTS `Stato` ;

CREATE TABLE IF NOT EXISTS `Stato` (
  `CodEd` VARCHAR(13) NOT NULL,
  `Data` DATE NOT NULL,
  `Generale` CHAR(1) NULL,
  `Calamitoso` CHAR(1) NULL,
  PRIMARY KEY (`CodEd`, `Data`),
  CONSTRAINT `fk_Stato_Edificio2`
    FOREIGN KEY (`CodEd`)
    REFERENCES `Edificio` (`Codice`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION)
ENGINE = InnoDB;


-- -----------------------------------------------------
-- Table `Vano`
-- -----------------------------------------------------
DROP TABLE IF EXISTS `Vano` ;

CREATE TABLE IF NOT EXISTS `Vano` (
  `CodEd` VARCHAR(13) NOT NULL,
  `Codice` VARCHAR(10) NOT NULL,
  `Hmax` INT NULL,
  `HMin` INT NULL,
  `Larghezza` INT NULL,
  `Lunghezza` INT NULL,
  `Metratura` INT NULL,
  `Funzione` VARCHAR(45) NOT NULL,
  `NumSensori` INT NOT NULL,
  `Piano` INT NULL,
  PRIMARY KEY (`Codice`),
  INDEX `fk_Vano_Edificio1_idx` (`CodEd` ASC) VISIBLE,
  CONSTRAINT `fk_Vano_Edificio1`
    FOREIGN KEY (`CodEd`)
    REFERENCES `Edificio` (`Codice`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION)
ENGINE = InnoDB;


-- -----------------------------------------------------
-- Table `Muro`
-- -----------------------------------------------------
DROP TABLE IF EXISTS `Muro` ;

CREATE TABLE IF NOT EXISTS `Muro` (
  `Codice` VARCHAR(10) NOT NULL,
  `Altezza` INT NOT NULL,
  `Lunghezza` INT NOT NULL,
  `Linea` VARCHAR(45) NOT NULL,
  PRIMARY KEY (`Codice`))
ENGINE = InnoDB;


-- -----------------------------------------------------
-- Table `Parete`
-- -----------------------------------------------------
DROP TABLE IF EXISTS `Parete` ;

CREATE TABLE IF NOT EXISTS `Parete` (
  `CodVano` VARCHAR(10) NOT NULL,
  `CodMuro` VARCHAR(10) NOT NULL,
  `Orientamento` CHAR(3) NOT NULL,
  PRIMARY KEY (`CodMuro`, `CodVano`),
  INDEX `fk_Parete_Vano1_idx` (`CodVano` ASC) VISIBLE,
  CONSTRAINT `fk_Parete_Muro1`
    FOREIGN KEY (`CodMuro`)
    REFERENCES `Muro` (`Codice`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION,
  CONSTRAINT `fk_Parete_Vano1`
    FOREIGN KEY (`CodVano`)
    REFERENCES `Vano` (`Codice`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION)
ENGINE = InnoDB;


-- -----------------------------------------------------
-- Table `Sensore`
-- -----------------------------------------------------
DROP TABLE IF EXISTS `Sensore` ;

CREATE TABLE IF NOT EXISTS `Sensore` (
  `Codice` VARCHAR(5) NOT NULL,
  `CodVano` VARCHAR(10) NOT NULL,
  `CodMuro` VARCHAR(10) NOT NULL,
  `PosOrizzontale` INT NOT NULL,
  `PosVerticale` INT NOT NULL,
  PRIMARY KEY (`Codice`),
  INDEX `fk_Sensore_Parete2_idx` ( `CodVano` ASC, `CodMuro` ASC) VISIBLE,
  CONSTRAINT `fk_Sensore_Parete2`
    FOREIGN KEY ( `CodVano`, `CodMuro`)
    REFERENCES `Parete` ( `CodVano`, `CodMuro` )
    ON DELETE NO ACTION
    ON UPDATE NO ACTION)
ENGINE = InnoDB;


-- -----------------------------------------------------
-- Table `SensoreSismico`
-- -----------------------------------------------------
DROP TABLE IF EXISTS `SensoreSismico` ;

CREATE TABLE IF NOT EXISTS `SensoreSismico` (
  `CodSensore` VARCHAR(5) NOT NULL,
  `Tipo` VARCHAR(45) NOT NULL,
  `SogliaX` FLOAT(5) NOT NULL,
  `SogliaY` FLOAT(5) NOT NULL,
  `SogliaZ` FLOAT(5) NOT NULL,
  PRIMARY KEY (`CodSensore`),
  CONSTRAINT `fk_SensoreSismico_Sensore1`
    FOREIGN KEY (`CodSensore`)
    REFERENCES `Sensore` (`Codice`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION)
ENGINE = InnoDB;


-- -----------------------------------------------------
-- Table `SensoreAmbientale`
-- -----------------------------------------------------
DROP TABLE IF EXISTS `SensoreAmbientale` ;

CREATE TABLE IF NOT EXISTS `SensoreAmbientale` (
  `CodSensore` VARCHAR(5) NOT NULL,
  `Tipo` VARCHAR(45) NOT NULL,
  `Soglia` FLOAT(5) NOT NULL,
  PRIMARY KEY (`CodSensore`),
  CONSTRAINT `fk_SensoreAmbientale_Sensore1`
    FOREIGN KEY (`CodSensore`)
    REFERENCES `Sensore` (`Codice`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION)
ENGINE = InnoDB;


-- -----------------------------------------------------
-- Table `MisurazioneSismica`
-- -----------------------------------------------------
DROP TABLE IF EXISTS `MisurazioneSismica` ;

CREATE TABLE IF NOT EXISTS `MisurazioneSismica` (
  `CodSensore` VARCHAR(5) NOT NULL,
  `Timestamp` DATETIME NOT NULL,
  `ValX` FLOAT(5) NOT NULL,
  `ValY` FLOAT(5) NOT NULL,
  `ValZ` FLOAT(5) NOT NULL,
  PRIMARY KEY (`CodSensore`, `Timestamp`),
  CONSTRAINT `fk_MisurazioneAmbientale_SensoreSismico1`
    FOREIGN KEY (`CodSensore`)
    REFERENCES `SensoreSismico` (`CodSensore`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION)
ENGINE = InnoDB;


-- -----------------------------------------------------
-- Table `AlertSismico`
-- -----------------------------------------------------
DROP TABLE IF EXISTS `AlertSismico` ;

CREATE TABLE IF NOT EXISTS `AlertSismico` (
  `CodSensore` VARCHAR(5) NOT NULL,
  `TimeStamp` DATETIME NOT NULL,
  `ValX` FLOAT(5) NOT NULL,
  `ValY` FLOAT(5) NOT NULL,
  `ValZ` FLOAT(5) NOT NULL,
  PRIMARY KEY (`CodSensore`, `TimeStamp`),
  INDEX `fk_AlertSismico_SensoreSismico1_idx` (`CodSensore` ASC) VISIBLE,
  CONSTRAINT `fk_AlertSismico_SensoreSismico1`
    FOREIGN KEY (`CodSensore`)
    REFERENCES `SensoreSismico` (`CodSensore`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION)
ENGINE = InnoDB;


-- -----------------------------------------------------
-- Table `MisurazioneAmbientale`
-- -----------------------------------------------------
DROP TABLE IF EXISTS `MisurazioneAmbientale` ;

CREATE TABLE IF NOT EXISTS `MisurazioneAmbientale` (
  `CodSensore` VARCHAR(5) NOT NULL,
  `Timestamp` DATETIME NOT NULL,
  `Valore` FLOAT(5) NOT NULL,
  PRIMARY KEY (`CodSensore`, `Timestamp`),
  INDEX `fk_MisurazioneAmbientale_SensoreAmbientale1_idx` (`CodSensore` ASC) VISIBLE,
  CONSTRAINT `fk_MisurazioneAmbientale_SensoreAmbientale1`
    FOREIGN KEY (`CodSensore`)
    REFERENCES `SensoreAmbientale` (`CodSensore`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION)
ENGINE = InnoDB;


-- -----------------------------------------------------
-- Table `alertAmbientale`
-- -----------------------------------------------------
DROP TABLE IF EXISTS `alertAmbientale` ;

CREATE TABLE IF NOT EXISTS `alertAmbientale` (
  `CodSensore` VARCHAR(5) NOT NULL,
  `Timestamp` DATETIME NOT NULL,
  `Valore` FLOAT(5) NOT NULL,
  PRIMARY KEY (`CodSensore`, `Timestamp`),
  CONSTRAINT `fk_alertAmbientale_SensoreAmbientale1`
    FOREIGN KEY (`CodSensore`)
    REFERENCES `SensoreAmbientale` (`CodSensore`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION)
ENGINE = InnoDB;

		

-- -----------------------------------------------------
-- Table `ViaDiAccesso`
-- -----------------------------------------------------
DROP TABLE IF EXISTS `ViaDiAccesso` ;

CREATE TABLE IF NOT EXISTS `ViaDiAccesso` (
  `CodMuro` VARCHAR(10) NOT NULL,
  `PosVerticale` INT NOT NULL,
  `PosOrizzontale` INT NOT NULL,
  `Tipo` VARCHAR(45) NOT NULL,
  `Forma` VARCHAR(45) NULL,
  `Altezza` INT NOT NULL,
  `Lunghezza` INT NOT NULL,
  `LatoApertura` VARCHAR(10) NULL,
  PRIMARY KEY (`CodMuro`, `PosVerticale`, `PosOrizzontale`),
  INDEX `fk_ViaDiAccesso_Vano1_idx` (`LatoApertura` ASC) VISIBLE,
  CONSTRAINT `fk_ViaDiAccesso_Muro1`
    FOREIGN KEY (`CodMuro`)
    REFERENCES `Muro` (`Codice`)
    ON DELETE CASCADE
    ON UPDATE CASCADE,
  CONSTRAINT `fk_ViaDiAccesso_Vano1`
    FOREIGN KEY (`LatoApertura`)
    REFERENCES `Vano` (`Codice`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION)
ENGINE = InnoDB;


-- -----------------------------------------------------
-- Table `Materiale`
-- -----------------------------------------------------
DROP TABLE IF EXISTS `Materiale` ;

CREATE TABLE IF NOT EXISTS `Materiale` (
  `CodProdotto` VARCHAR(5) NOT NULL,
  `Fornitore` VARCHAR(45) NOT NULL,
  `Costo` INT NOT NULL,
  `Pezzi` INT NOT NULL,
  PRIMARY KEY (`CodProdotto`))
ENGINE = InnoDB;


-- -----------------------------------------------------
-- Table `ComposizioneMuro`
-- -----------------------------------------------------
DROP TABLE IF EXISTS `ComposizioneMuro` ;

CREATE TABLE IF NOT EXISTS `ComposizioneMuro` (
  `CodProdotto` VARCHAR(15) NOT NULL,
  `CodMuro` VARCHAR(10) NOT NULL,
  `Quantita` INT NOT NULL,
  PRIMARY KEY (`CodProdotto`, `CodMuro`),
  INDEX `fk_table2_Muro1_idx` (`CodMuro` ASC) VISIBLE,
  CONSTRAINT `fk_ComposizioneMuro_Materiale1`
    FOREIGN KEY (`CodProdotto`)
    REFERENCES `Materiale` (`CodProdotto`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION,
  CONSTRAINT `fk_ComposizioneMuro_Muro1`
    FOREIGN KEY (`CodMuro`)
    REFERENCES `Muro` (`Codice`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION)
ENGINE = InnoDB;


-- -----------------------------------------------------
-- Table `CompsizioneParete`
-- -----------------------------------------------------
DROP TABLE IF EXISTS `ComposizioneParete` ;

CREATE TABLE IF NOT EXISTS `ComposizioneParete` (
  `CodProdotto` VARCHAR(15) NOT NULL,
  `CodMuro` VARCHAR(10) NOT NULL,
  `CodVano` VARCHAR(10) NOT NULL,
  `Quantita` INT NULL,
  PRIMARY KEY (`CodProdotto`, `CodMuro`, `CodVano`),
  INDEX `fk_table3_Parete1_idx` (`CodMuro` ASC, `CodVano` ASC) VISIBLE,
  CONSTRAINT `fk_ComposizioneParete_Materiale1`
    FOREIGN KEY (`CodProdotto`)
    REFERENCES `Materiale` (`CodProdotto`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION,
  CONSTRAINT `fk_ComposizioneParete_Parete1`
    FOREIGN KEY (`CodMuro`)
    REFERENCES `Parete` (`CodMuro`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION)
ENGINE = InnoDB;


-- -----------------------------------------------------
-- Table `ProgettoEdilizio`
-- -----------------------------------------------------
DROP TABLE IF EXISTS `ProgettoEdilizio` ;

CREATE TABLE IF NOT EXISTS `ProgettoEdilizio` (
  `Codice` VARCHAR(15) NOT NULL,
  `DataPresentazione` DATE NOT NULL,
  `DataApprovazione` DATE NOT NULL,
  `DataInizo` DATE NOT NULL,
  `StimaFine` DATE NOT NULL,
  `CodEd` VARCHAR(13) NOT NULL,
  PRIMARY KEY (`Codice`),
  INDEX `fk_ProgettoEdilizio_Edificio1_idx` (`CodEd` ASC) VISIBLE,
  CONSTRAINT `fk_ProgettoEdilizio_Edificio1`
    FOREIGN KEY (`CodEd`)
    REFERENCES `Edificio` (`Codice`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION)
ENGINE = InnoDB;


-- -----------------------------------------------------
-- Table `Stadio`
-- -----------------------------------------------------
DROP TABLE IF EXISTS `Stadio` ;

CREATE TABLE IF NOT EXISTS `Stadio` (
  `CodProgetto` VARCHAR(15) NOT NULL,
  `Livello` INT NOT NULL,
  `Nome` VARCHAR(45) NOT NULL,
  `DataInizio` DATE NOT NULL,
  `StimaFine` DATE NOT NULL,
  PRIMARY KEY (`CodProgetto`, `Livello`),
  CONSTRAINT `fk_Stadio_ProgettoEdilizio1`
    FOREIGN KEY (`CodProgetto`)
    REFERENCES `ProgettoEdilizio` (`Codice`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION)
ENGINE = InnoDB;


-- -----------------------------------------------------
-- Table `Lavoro`
-- -----------------------------------------------------
DROP TABLE IF EXISTS `Lavoro` ;

CREATE TABLE IF NOT EXISTS `Lavoro` (
  `Codice` VARCHAR(15) NOT NULL,
  `CodProgetto` VARCHAR(15) NOT NULL,
  `CodStadio` INT NOT NULL,
  `Descrizione` VARCHAR(45) NOT NULL,
  `Costo` INT DEFAULT 0,
  PRIMARY KEY (`Codice`),
  INDEX `fk_Lavoro_Stadio1_idx` (`CodProgetto` ASC, `CodStadio` ASC) VISIBLE,
  CONSTRAINT `fk_Lavoro_Stadio1`
    FOREIGN KEY (`CodProgetto` , `CodStadio`)
    REFERENCES `Stadio` (`CodProgetto` , `Livello`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION)
ENGINE = InnoDB;


-- -----------------------------------------------------
-- Table `Produzione`
-- -----------------------------------------------------
DROP TABLE IF EXISTS `Produzione` ;

CREATE TABLE IF NOT EXISTS `Produzione` (
  `Lotto` VARCHAR(20) NOT NULL,
  `CodProdotto` VARCHAR(5) NOT NULL,
  PRIMARY KEY (`Lotto`),
  INDEX `fk_Produzione_Materiale1_idx` (`CodProdotto` ASC) VISIBLE,
  CONSTRAINT `fk_Produzione_Materiale1`
    FOREIGN KEY (`CodProdotto`)
    REFERENCES `Materiale` (`CodProdotto`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION)
ENGINE = InnoDB;


-- -----------------------------------------------------
-- Table `Schedario`
-- -----------------------------------------------------
DROP TABLE IF EXISTS `Schedario` ;

CREATE TABLE IF NOT EXISTS `Schedario` (
  `Lavoro` VARCHAR(15) NOT NULL,
  `Lotto` VARCHAR(20) NOT NULL,
  `DataAcquisto` DATE NOT NULL,
  `Quantita` INT NOT NULL,
  PRIMARY KEY (`Lavoro`, `Lotto`, `DataAcquisto`),
  INDEX `fk_Schedario_Lavoro1_idx` (`Lavoro` ASC) VISIBLE,
  INDEX `fk_Schedario_Produzione1_idx` (`Lotto` ASC) VISIBLE,
  CONSTRAINT `fk_Schedario_Lavoro1`
    FOREIGN KEY (`Lavoro`)
    REFERENCES `Lavoro` (`Codice`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION,
  CONSTRAINT `fk_Schedario_Produzione1`
    FOREIGN KEY (`Lotto`)
    REFERENCES `Produzione` (`Lotto`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION)
ENGINE = InnoDB;


-- -----------------------------------------------------
-- Table `Responsabile`
-- -----------------------------------------------------
DROP TABLE IF EXISTS `Responsabile` ;

CREATE TABLE IF NOT EXISTS `Responsabile` (
  `CodFiscale` VARCHAR(16) NOT NULL,
  `Nome` VARCHAR(45) NOT NULL,
  `Cognome` VARCHAR(45) NOT NULL,
  `Parcella` INT NOT NULL,
  PRIMARY KEY (`CodFiscale`))
ENGINE = InnoDB;


-- -----------------------------------------------------
-- Table `Collaudo`
-- -----------------------------------------------------
DROP TABLE IF EXISTS `Collaudo` ;

CREATE TABLE IF NOT EXISTS `Collaudo` (
  `Lavoro` VARCHAR(15) NOT NULL,
  `Responsabile` VARCHAR(16) NOT NULL,
  PRIMARY KEY (`Lavoro`, `Responsabile`),
  INDEX `fk_table8_Lavoro1_idx` (`Lavoro` ASC) VISIBLE,
  CONSTRAINT `fk_Collaudo_Responsabile1`
    FOREIGN KEY (`Responsabile`)
    REFERENCES `Responsabile` (`CodFiscale`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION,
  CONSTRAINT `fk_Collaudo_Lavoro1`
    FOREIGN KEY (`Lavoro`)
    REFERENCES `Lavoro` (`Codice`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION)
ENGINE = InnoDB;


-- -----------------------------------------------------
-- Table `Lavoratore`
-- -----------------------------------------------------
DROP TABLE IF EXISTS `Lavoratore` ;

CREATE TABLE IF NOT EXISTS `Lavoratore` (
  `CodFiscale` VARCHAR(16) NOT NULL,
  `Nome` VARCHAR(45) NOT NULL,
  `Cognome` VARCHAR(45) NOT NULL,
  `Stipendio` INT NOT NULL,
  PRIMARY KEY (`CodFiscale`))
ENGINE = InnoDB;


-- -----------------------------------------------------
-- Table `Turno`
-- -----------------------------------------------------
DROP TABLE IF EXISTS `Turno` ;

CREATE TABLE IF NOT EXISTS `Turno` (
  `Data` DATE NOT NULL,
  `Ora` INT NOT NULL,
    `Lavoro` VARCHAR(15) NOT NULL,
  PRIMARY KEY (`Lavoro`, `Data`, `Ora`),
  INDEX `fk_Turno_Lavoro1_idx` (`Lavoro` ASC) VISIBLE,
  CONSTRAINT `fk_Turno_Lavoro1`
    FOREIGN KEY (`Lavoro`)
    REFERENCES `Lavoro` (`Codice`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION)
ENGINE = InnoDB;


-- -----------------------------------------------------
-- Table `Realizzazione`
-- -----------------------------------------------------
DROP TABLE IF EXISTS `Realizzazione` ;

CREATE TABLE IF NOT EXISTS `Realizzazione` (
  `Lavoro` VARCHAR(15) NOT NULL,
  `Data` DATE NOT NULL,
  `Ora` INT NOT NULL,
  `Lavoratore` VARCHAR(16) NOT NULL,
  PRIMARY KEY (`Lavoro`, `Data`, `Ora`, `Lavoratore`),
  INDEX `fk_Realizzazione_Turno1_idx` (`Lavoro` ASC, `Data` ASC, `Ora` ASC) VISIBLE,
  CONSTRAINT `fk_Realizzazione_Lavoratore1`
    FOREIGN KEY (`Lavoratore`)
    REFERENCES `Lavoratore` (`CodFiscale`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION,
  CONSTRAINT `fk_Realizzazione_Turno1`
    FOREIGN KEY (`Lavoro` , `Data` , `Ora`)
    REFERENCES `Turno` (`Lavoro` , `Data` , `Ora`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION)
ENGINE = InnoDB;


-- -----------------------------------------------------
-- Table `Capocantiere`
-- -----------------------------------------------------
DROP TABLE IF EXISTS `Capocantiere` ;

CREATE TABLE IF NOT EXISTS `Capocantiere` (
  `CodFiscale` VARCHAR(16) NOT NULL,
  `Nome` VARCHAR(45) NOT NULL,
  `Cognome` VARCHAR(45) NOT NULL,
  `Stipendio` INT NOT NULL,
  `MaxOperai` INT NOT NULL,
  PRIMARY KEY (`CodFiscale`))
ENGINE = InnoDB;


-- -----------------------------------------------------
-- Table `Direzione`
-- -----------------------------------------------------
DROP TABLE IF EXISTS `Direzione` ;

CREATE TABLE IF NOT EXISTS `Direzione` (
  `Lavoro` VARCHAR(15) NOT NULL,
  `Data` DATE NOT NULL,
  `Ora` INT NOT NULL,
  `Capocantiere` VARCHAR(16) NOT NULL,
  PRIMARY KEY (`Lavoro`, `Data`, `Ora`, `Capocantiere`),
  INDEX `fk_Direzione_Capocantiere1_idx` (`Capocantiere` ASC) VISIBLE,
  INDEX `fk_Direzione_Turno1_idx` (`Lavoro` ASC, `Data` ASC, `Ora` ASC) VISIBLE,
  CONSTRAINT `fk_Direzione_Capocantiere1`
    FOREIGN KEY (`Capocantiere`)
    REFERENCES `Capocantiere` (`CodFiscale`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION,
  CONSTRAINT `fk_Direzione_Turno1`
    FOREIGN KEY (`Lavoro` , `Data` , `Ora`)
    REFERENCES `Turno` (`Lavoro` , `Data` , `Ora`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION)
ENGINE = InnoDB;


-- -----------------------------------------------------
-- Table `MaterialeGenerico`
-- -----------------------------------------------------
DROP TABLE IF EXISTS `MaterialeGenerico` ;

CREATE TABLE IF NOT EXISTS `MaterialeGenerico` (
  `CodProdotto` VARCHAR(5) NOT NULL,
  `Nome` VARCHAR(45) NOT NULL,
  `Altezza` INT NOT NULL,
  `Lunghezza` INT NOT NULL,
  `Spessore` INT NOT NULL,
  `Peso` INT NOT NULL,
  PRIMARY KEY (`CodProdotto`),
  CONSTRAINT `fk_MaterialeGenerico_Materiale2`
    FOREIGN KEY (`CodProdotto`)
    REFERENCES `Materiale` (`CodProdotto`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION)
ENGINE = InnoDB;


-- -----------------------------------------------------
-- Table `Pietra`
-- -----------------------------------------------------
DROP TABLE IF EXISTS `Pietra` ;

CREATE TABLE IF NOT EXISTS `Pietra` (
  `CodProdotto` VARCHAR(5) NOT NULL,
  `Disposizione` VARCHAR(45) NOT NULL,
  `Peso` INT NOT NULL,
  `Superficie` INT NOT NULL,
  `Composizione` VARCHAR(45) NOT NULL,
  PRIMARY KEY (`CodProdotto`),
  CONSTRAINT `fk_Pietra_Materiale2`
    FOREIGN KEY (`CodProdotto`)
    REFERENCES `Materiale` (`CodProdotto`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION)
ENGINE = InnoDB;


-- -----------------------------------------------------
-- Table `Intonaco`
-- -----------------------------------------------------
DROP TABLE IF EXISTS `Intonaco` ;

CREATE TABLE IF NOT EXISTS `Intonaco` (
  `CodProdotto` VARCHAR(5) NOT NULL,
   `Tipo` VARCHAR(45) NOT NULL,
  `Composizione` VARCHAR(45) NOT NULL,
  `Strato` INT NOT NULL,
  `Spessore` INT NOT NULL,
  PRIMARY KEY (`CodProdotto`),
  CONSTRAINT `fk_intonaco_Materiale1`
    FOREIGN KEY (`CodProdotto`)
    REFERENCES `Materiale` (`CodProdotto`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION)
ENGINE = InnoDB;


-- -----------------------------------------------------
-- Table `Piastrella`
-- -----------------------------------------------------
DROP TABLE IF EXISTS `Piastrella` ;

CREATE TABLE IF NOT EXISTS `Piastrella` (
  `CodProdotto` VARCHAR(5) NOT NULL,
  `Disegno` VARCHAR(45) NULL,
  `Fuga` INT NOT NULL,
  `Forma` VARCHAR(45) NOT NULL,
  `Composizione` VARCHAR(45) NOT NULL,
  `Lunghezza` INT NOT NULL,
  `Larghezza` INT NOT NULL,
  `Spessore` INT NOT NULL,
  PRIMARY KEY (`CodProdotto`),
  CONSTRAINT `fk_piastrella_Materiale1`
    FOREIGN KEY (`CodProdotto`)
    REFERENCES `Materiale` (`CodProdotto`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION)
ENGINE = InnoDB;


-- -----------------------------------------------------
-- Table `Alveolatura`
-- -----------------------------------------------------
DROP TABLE IF EXISTS `Alveolatura` ;

CREATE TABLE IF NOT EXISTS `Alveolatura` (
  `Nome` VARCHAR(5) NOT NULL,
  `Larghezza` INT NOT NULL,
  `Lunghezza` INT NOT NULL,
  `Spessore` INT NOT NULL,
  `Contenuto` VARCHAR(45)  NOT NULL,
  `FormaFori` VARCHAR(45) NOT NULL,
  `NumFori` INT NOT NULL,
  PRIMARY KEY (`Nome`))
ENGINE = InnoDB;


-- -----------------------------------------------------
-- Table `Mattone`
-- -----------------------------------------------------
DROP TABLE IF EXISTS `Mattone` ;

CREATE TABLE IF NOT EXISTS `Mattone` (
  `CodProdotto` VARCHAR(5) NOT NULL,
  `Larghezza` INT NOT NULL,
  `Lunghezza` INT NOT NULL,
  `Spessore` INT NOT NULL,
  `Composizione` VARCHAR(45) NOT NULL,
  `Alveolatura` VARCHAR(5) NULL,
  PRIMARY KEY (`CodProdotto`),
  INDEX `fk_Mattone_Alveolatura1_idx` (`Alveolatura` ASC) VISIBLE,
  CONSTRAINT `fk_Mattone_Materiale1`
    FOREIGN KEY (`CodProdotto`)
    REFERENCES `Materiale` (`CodProdotto`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION,
  CONSTRAINT `fk_Mattone_Alveolatura1`
    FOREIGN KEY (`Alveolatura`)
    REFERENCES `Alveolatura` (`Nome`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION)
ENGINE = InnoDB;


-- -----------------------------------------------------
-- Table `Danno`
-- -----------------------------------------------------
DROP TABLE IF EXISTS `Danno` ;

CREATE TABLE IF NOT EXISTS `Danno` (
  `Codice` INT NOT NULL,
  `Descrizione` VARCHAR(45) NOT NULL,
  `DataComparsa` DATE NOT NULL,
  PRIMARY KEY (`Codice`))
ENGINE = InnoDB;


-- -----------------------------------------------------
-- Table `Riparazione`
-- -----------------------------------------------------
DROP TABLE IF EXISTS `Riparazione` ;

CREATE TABLE IF NOT EXISTS `Riparazione` (
  `Danno` INT NOT NULL,
  `Lavoro` VARCHAR(15) NOT NULL,
  PRIMARY KEY (`Danno`, `Lavoro`),
  INDEX `fk_Riparazione_Lavoro1_idx` (`Lavoro` ASC) VISIBLE,
  CONSTRAINT `fk_Riparazione_Danno1`
    FOREIGN KEY (`Danno`)
    REFERENCES `Danno` (`Codice`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION,
  CONSTRAINT `fk_Riparazione_Lavoro1`
    FOREIGN KEY (`Lavoro`)
    REFERENCES `Lavoro` (`Codice`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION)
ENGINE = InnoDB;


-- -----------------------------------------------------
-- Table `Parete Danneggiata`
-- -----------------------------------------------------
DROP TABLE IF EXISTS `PareteDanneggiata` ;

CREATE TABLE IF NOT EXISTS `PareteDanneggiata` (
  `CodDanno` INT NOT NULL,
  `CodVano` VARCHAR(10) NOT NULL,
  `CodMuro` VARCHAR(10) NOT NULL,
  PRIMARY KEY (`CodMuro`, `CodVano`, `CodDanno`),
  INDEX `fk_Parete Danneggiata_Danno1_idx` (`CodDanno` ASC) VISIBLE,
  CONSTRAINT `fk_Parete Danneggiata_Parete1`
    FOREIGN KEY (`CodMuro` , `CodVano`)
    REFERENCES `Parete` (`CodMuro` , `CodVano`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION,
  CONSTRAINT `fk_Parete Danneggiata_Danno1`
    FOREIGN KEY (`CodDanno`)
    REFERENCES `Danno` (`Codice`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION)
ENGINE = InnoDB;


SET SQL_MODE=@OLD_SQL_MODE;
SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS;
SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS;
