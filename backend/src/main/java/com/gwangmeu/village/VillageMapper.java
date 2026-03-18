package com.gwangmeu.village;

import com.gwangmeu.village.domain.Village;
import com.gwangmeu.village.dto.VillageDto;
import org.mapstruct.Mapper;

@Mapper(componentModel = "spring")
public interface VillageMapper {

    VillageDto toDto(Village village);
}
