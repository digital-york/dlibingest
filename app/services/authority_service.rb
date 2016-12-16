module AuthorityService

# Object based
	class SubjectService < Dlibhydra::Terms::SubjectTerms
		include ::LocalAuthorityConcern
	end
	class CurrentOrganisationService < Dlibhydra::Terms::CurrentOrganisationTerms
		include ::LocalAuthorityConcern
	end
	class CurrentPersonService < Dlibhydra::Terms::CurrentPersonTerms
		include ::LocalAuthorityConcern
	end
	class QualificationNameService < Dlibhydra::Terms::QualificationNameTerms
		include ::LocalAuthorityConcern
	end
	class DepartmentService < Dlibhydra::Terms::DepartmentTerms
		include ::LocalAuthorityConcern
	end

# File based
	class ResourceTypesService < CurationConcerns::QaSelectService
	include ::FileAuthorityConcern
		def initialize
			super('resource_types')
		end
	end
	class LanguagesService < CurationConcerns::QaSelectService
	include ::FileAuthorityConcern
		def initialize
			super('languages')
		end
	end
	class QualificationLevelsService < CurationConcerns::QaSelectService
	include ::FileAuthorityConcern
		def initialize
			super('qualification_levels')
		end
	end
	class LicensesService < CurationConcerns::QaSelectService
	include ::FileAuthorityConcern
		def initialize
			super('licenses')
		end
	end
	class RightsStatementsService < CurationConcerns::QaSelectService
	include ::FileAuthorityConcern
		def initialize
			super('rights_statements')
		end
	end

end