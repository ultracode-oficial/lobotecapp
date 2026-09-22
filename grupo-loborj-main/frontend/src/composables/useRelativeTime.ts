export function useRelativeTime() {
  const getRelativeTime = (date: Date | string) => {
    const now = new Date();
    const past = new Date(date);
    const diffInSeconds = (past.valueOf() - now.valueOf()) / 1000;

    const rtf = new Intl.RelativeTimeFormat('pt-BR', { numeric: 'auto' });

    const units: { unit: Intl.RelativeTimeFormatUnit, value: number }[] = [
      { unit: 'year', value: 31536000 },
      { unit: 'month', value: 2592000 },
      { unit: 'day', value: 86400 },
      { unit: 'hour', value: 3600 },
      { unit: 'minute', value: 60 },
      { unit: 'second', value: 1 }
    ];

    for (const { unit, value } of units) {
      if (Math.abs(diffInSeconds) >= value || unit === 'second') {
        return rtf.format(Math.round(diffInSeconds / value), unit);
      }
    }
  };

  return { getRelativeTime };
}