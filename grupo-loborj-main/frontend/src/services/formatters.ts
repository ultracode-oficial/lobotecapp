export const formatCPF = (value: string) => value.replace(/\D/g, '').replace(/(\d{3})(\d{3})(\d{3})(\d{2})/, '$1.$2.$3-$4');

export const formatCNPJ = (value: string) => value.replace(/[^0-9a-zA-Z]/g, '').replace(/([0-9a-zA-Z]{2})([0-9a-zA-Z]{3})([0-9a-zA-Z]{3})([0-9a-zA-Z]{4})([0-9a-zA-Z]{2})/, '$1.$2.$3/$4-$5')

export const formatPhone = (value: string) => value.replace(/\D/g, '').length === 11 ? value.replace(/(\d{2})(\d{5})/, '($1) $2-') : value.replace(/(\d{2})(\d{4})/, '($1) $2-');

export interface Endereco {
  cep?: string | null;
  logradouro?: string | null;
  numero_logradouro?: string | null;
  complemento?: string | null;
  bairro?: string | null;
  municipio?: string | null;
  uf?: string | null;
}

const isFilled = (value?: string | null): value is string =>
  value != null && value.trim().length > 0;

export function formatEndereco(address: Endereco): string | null {
  const {
    cep,
    logradouro,
    numero_logradouro,
    complemento,
    bairro,
    municipio,
    uf,
  } = address;

  const street = [
    logradouro,
    numero_logradouro && `nº ${numero_logradouro}`,
    complemento,
  ]
    .filter(isFilled)
    .join(", ");

  const city = [municipio, uf].filter(isFilled).join(" - ");

  const result = [street, bairro, city, cep && `CEP ${cep.replace(/(\d{5})/, "$1-")}`]
    .filter(isFilled)
    .join(", ");

  return result.trim().length > 0 ? result : null;
}