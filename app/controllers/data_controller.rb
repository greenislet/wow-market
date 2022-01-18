class DataController < ApplicationController
  def initialize
    @columns = [
      :slug,
      :blizz_id,
      :slug,
      :region,
      :status,
      :population,
      :category,
      :locale,
      :timezone,
    ]
  end
  def realms
    resp = {
      "draw": params["draw"],
    }
    if !params[:length].nil?
      step = params[:length].to_i
    else
      step = 10
    end
    page = params[:start].to_i
    if step > 100
      step = 100
    end

    column_idx = params[:order]["0"]["column"].to_i

    realms = Realm.select(:id, :blizz_id, :slug, :region, :status, :population, :category, :locale, :timezone)
    realms = realms.where("slug LIKE ?", "%#{params["search"]["value"]}%")
    realms = realms.order(@columns[column_idx] => params[:order]["0"]["dir"].to_sym)
    realms = realms.limit(step).offset(page)
    data = []
    ids = []
    realms.each do |realm|
      ids << realm[:id]
      data << [
        realm.realm_names.select(:name).where(locale: @locale).first[:name],
        realm[:blizz_id],
        realm[:slug],
        realm[:region],
        realm[:status],
        realm[:population],
        realm[:category],
        realm[:locale],
        realm[:timezone],
      ]
    end
    resp["ids"] = ids
    resp["data"] = data
    resp["recordsTotal"] = Realm.count
    resp["recordsFiltered"] = Realm.count
    render plain: JSON.generate(resp)
  end
end
