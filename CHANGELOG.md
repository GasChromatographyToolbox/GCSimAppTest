# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.1.0] - 2024-12-13
### Added
- Initial release
- Basic GC simulation functionality
- Web interface with temperature program controls
- Integration with GasChromatographySimulator.jl

### Changed
- None

### Fixed
- None

## [0.1.1] - 2024-12-21
### Added
- Docker container for deployment
- Environment variables for configuration (dev.jl, prod.jl, global.jl)

### Changed
- None

### Fixed
- None 

## [0.1.2] - 2025-01-03
### Added
- None

### Changed
- None

### Fixed
- Updated to GasChromatographySimulator.jl v0.5.1 to fix issue with aborted simulations because of missing data for n-alkanes in database used by ChemicalIdentifiers.jl

## [0.1.3] - 2025-01-27
### Added
- Version display in footer

### Changed
- In GC simulation changed the option 'ng' to 'true', as only simulations without spatial temperature gradient are supported in the Web App; this should result in faster simulations
- functions for GC simulation used in app.jl are now in separate file src/gc_simulation.jl

### Fixed
- None