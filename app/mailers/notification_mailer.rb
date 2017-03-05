class NotificationMailer < ApplicationMailer
  default from: 'tps@apientreprise.fr',
          to:  Proc.new { @user.email }

  def send_notification dossier, email
    vars_mailer(dossier)

    obj  = email.object_for_dossier dossier
    body = email.body_for_dossier dossier

    mail(subject: obj) { |format| format.html { body } }
  end

  def new_answer dossier
    send_mail dossier, "Nouveau message pour votre dossier TPS N°#{dossier.id}"
  end

  def dossier_submitted dossier
    send_mail dossier, "Votre dossier TPS N°#{dossier.id} a été déposé"
  end

  def dossier_without_continuation dossier
    send_mail dossier, "Votre dossier TPS N°#{dossier.id} a été classé sans suite"
  end

  def dossier_refused dossier
    send_mail dossier, "Votre dossier TPS N°#{dossier.id} a été refusé"
  end

  def dossier_closed dossier
    send_mail dossier, "Votre dossier TPS N°#{dossier.id} a été accepté"
  end

  private

  def vars_mailer dossier
    @dossier = dossier
    @user = dossier.user
  end

  def send_mail dossier, subject
    vars_mailer dossier

    mail(subject: subject)
  end
end
