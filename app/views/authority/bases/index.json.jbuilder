json.array!(@authority_bases) do |authority_basis|
  json.extract! authority_basis, :id
  json.url authority_basis_url(authority_basis, format: :json)
end
