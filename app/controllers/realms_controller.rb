class RealmsController < ApplicationController
  def index
    render 'index'
  end

  def show
    @realm = Realm.select(:id, :blizz_id, :slug, :region, :status, :population, :category, :locale, :timezone).where(id: params[:id]).first
    @realm_name = @realm.realm_names.select(:name).where(locale: @locale).first[:name]
    render 'show'
  end
end
