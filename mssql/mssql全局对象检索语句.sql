-- 全局查询数据库中所有对象的元信息及定义（支持全类型+多条件筛选）
SELECT 
    o.[name] AS ObjectName,                    -- 对象名称（支持LIKE模糊查询，如'%Order%'）
    o.[type] AS TypeCode,                      -- 对象类型代码（完整类型见下方注释）
    o.[type_desc] AS TypeDescription,          -- 类型描述（如'USER_TABLE','SQL_STORED_PROCEDURE'）
    o.create_date AS CreateDate,               -- 创建时间（支持BETWEEN范围筛选，如'2024-01-01~2024-03-31'）
    o.modify_date AS LastModifiedDate,         -- 最后修改时间（审计用，可检测未授权变更）
    SCHEMA_NAME(o.[schema_id]) AS SchemaName,  -- 所属架构（过滤示例：AND SCHEMA_NAME(o.[schema_id])='dbo'）
    m.[definition] AS ObjectDefinition         -- 对象定义文本（支持LIKE全文检索，如'%SocialSecurity%'）
    --CASE WHEN m.is_encrypted = 1 
        --THEN 'Yes' ELSE 'No' END AS IsEncrypted -- 是否加密（加密对象不可查看定义）
FROM 
    sys.objects o  -- 系统对象表（存储表/视图/存储过程/函数等所有对象元数据）
LEFT JOIN 
    sys.sql_modules m  -- 对象定义表（存储代码类对象的完整定义文本）
    ON o.object_id = m.object_id
WHERE 
    1=1  -- 动态条件开关（取消注释下方条件启用筛选）
    
    /* ================ 常用筛选条件（按需启用） ================ */
    
    -- 1. 按对象类型筛选（完整类型代码参考：
    -- U=用户表, V=视图, P=存储过程, 
    -- FN=标量函数, TF=表值函数, TR=触发器,
    -- PK=主键, F=外键, D=默认约束, R=规则, S=系统表
    AND o.[type] IN ('U','V','P','FN', 'TF') 
    
    -- 2. 按名称模糊匹配（包含查询）
    -- AND o.[name] LIKE '%Log%'  
    
    -- 3. 按创建时间范围查询（时间格式：YYYY-MM-DD）
    -- AND o.create_date BETWEEN '2023-01-01' AND GETDATE()
    
    -- 4. 按定义文本检索（如查找含敏感操作的存储过程）
    -- AND m.[definition] LIKE '%DELETE%' 
    AND m.[definition] LIKE '%0-9%'
    
    -- 5. 排除系统对象（默认包含，启用后仅查用户创建的对象）
    -- AND o.is_ms_shipped = 0  
    
    -- 6. 按加密状态过滤（如查找未加密的敏感对象）
    -- AND m.is_encrypted = 0  
    
    -- 7. 按架构过滤（如仅查dbo架构）
    -- AND SCHEMA_NAME(o.[schema_id]) = 'dbo' 
    
ORDER BY 
    o.[type], o.create_date DESC  -- 排序规则（按类型分类+创建时间倒序）
    
/* ================ 性能优化提示 ================ */
-- 1. 高频查询建议索引：
-- CREATE NONCLUSTERED INDEX IDX_objects_name ON sys.objects([name])
-- CREATE FULLTEXT INDEX ON sys.sql_modules(definition) ...

-- 2. 分页扩展：添加以下语句（需声明@PageSize和@PageNumber变量）
-- OFFSET (@PageNumber -1) * @PageSize ROWS
-- FETCH NEXT @PageSize ROWS ONLY

-- 3. 执行计划优化（避免参数嗅探问题）
 OPTION (RECOMPILE)
