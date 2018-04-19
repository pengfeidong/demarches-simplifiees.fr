module NewAdministrateur
  class ServicesController < AdministrateurController
    def new
    end

    def create
      service = Service.new(service_params)
      service.administrateur = current_administrateur
      if !service.save
        flash[:alert] = service.errors.full_messages
        render :new
      else
        redirect_to services_path, notice: "#{service.nom} créé"
      end
    end

    private

    def service_params
      params.require(:service).permit(:nom, :type_organisme)
    end
  end
end
