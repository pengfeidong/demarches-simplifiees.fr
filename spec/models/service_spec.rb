describe Service, type: :model do
  describe 'validation' do
    let(:administrateur) { create(:administrateur) }
    let(:params) do
      {
        nom: 'service des jardins',
        type_organisme: 'commune',
        administrateur_id: administrateur.id
      }
    end

    it { expect(Service.new(params).valid?).to be_truthy }

    context 'of type_organisme' do
      it 'should be set' do
        expect(Service.new(params.except(:type_organisme)).valid?).to be_falsey
      end
    end

    context 'of nom' do
      it 'should be set' do
        expect(Service.new(params.except(:nom)).valid?).to be_falsey
      end
    end

    context 'of administrateur' do
      it 'should be set' do
        expect(Service.new(params.except(:administrateur_id)).valid?).to be_falsey
      end
    end
  end
end
